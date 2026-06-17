from typing import Any

import pandas as pd

from app.services import ml_model_loader_service
from app.services.ml_feature_service import (
    build_batch_feature_row,
    build_online_feature_row,
)


class MLInferenceError(RuntimeError):
    pass


def predict_batch(fecha, lugar: str, tramo: str) -> dict[str, Any]:
    bundle = ml_model_loader_service.get_batch_bundle()
    row = build_batch_feature_row(fecha=fecha, lugar=lugar, tramo=tramo)
    return _predict(bundle, row)


def predict_online(fecha, hora, lugar: str, tramo: str, tipo_incidente: str) -> dict[str, Any]:
    bundle = ml_model_loader_service.get_online_bundle()
    row = build_online_feature_row(
        fecha=fecha,
        hora=hora,
        lugar=lugar,
        tramo=tramo,
        tipo_incidente=tipo_incidente,
    )
    return _predict(bundle, row)


def _predict(bundle: dict[str, Any], row: dict[str, Any]) -> dict[str, Any]:
    features = list(bundle["features"])
    missing_features = [feature for feature in features if feature not in row]
    if missing_features:
        raise MLInferenceError(f"Faltan features para inferencia: {missing_features}")

    frame = pd.DataFrame([{feature: row[feature] for feature in features}], columns=features)
    pred_model = bundle["pipeline"].predict(frame)[0]
    return _convert_prediction(pred_model, bundle)


def _convert_prediction(pred_model: Any, bundle: dict[str, Any]) -> dict[str, Any]:
    class_map = bundle["class_map"]
    risk_label_map = bundle["risk_label_map"]

    mapped_score = _mapping_get(class_map, pred_model)
    if mapped_score is None:
        raise MLInferenceError(f"class_map no contiene la clase predicha: {pred_model}")

    try:
        score_riesgo = int(mapped_score)
    except (TypeError, ValueError) as exc:
        raise MLInferenceError(f"class_map devolvió un score inválido: {mapped_score}") from exc

    if score_riesgo not in (1, 2, 3):
        raise MLInferenceError(f"score_riesgo fuera de rango: {score_riesgo}")

    nivel_riesgo = _mapping_get(risk_label_map, score_riesgo)
    if nivel_riesgo is None:
        raise MLInferenceError(f"risk_label_map no contiene score_riesgo: {score_riesgo}")

    nivel_normalizado = str(nivel_riesgo).strip().lower()
    if nivel_normalizado not in {"bajo", "medio", "alto"}:
        raise MLInferenceError(f"nivel_riesgo inválido: {nivel_riesgo}")

    return {
        "score_riesgo": score_riesgo,
        "nivel_riesgo": nivel_normalizado,
    }


def _mapping_get(mapping: dict, key: Any) -> Any:
    candidates = [key]

    try:
        candidates.append(int(key))
    except (TypeError, ValueError):
        pass

    candidates.append(str(key))

    for candidate in candidates:
        if candidate in mapping:
            return mapping[candidate]

    return None

