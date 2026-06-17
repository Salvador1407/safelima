import joblib
import pandas as pd

from datetime import datetime
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent

BATCH_MODEL_PATH = BASE_DIR / "app" / "ml_models" / "modelo_riesgo_batch.pkl"
ONLINE_MODEL_PATH = BASE_DIR / "app" / "ml_models" / "modelo_riesgo_online.pkl"


def convertir_prediccion(pred_model: int, bundle: dict) -> dict:
    score_riesgo = bundle["class_map"][int(pred_model)]
    nivel_riesgo = bundle["risk_label_map"][score_riesgo]

    return {
        "score_riesgo": score_riesgo,
        "nivel_riesgo": nivel_riesgo,
        "pred_model_debug": int(pred_model),
    }


def probar_batch():
    bundle = joblib.load(BATCH_MODEL_PATH)
    pipe = bundle["pipeline"]

    fecha = "2025-11-22"
    lugar = "Jirón de la Unión"
    tramo = "Mañana"

    dt = datetime.fromisoformat(fecha)

    fila = pd.DataFrame([{
        "anio": dt.year,
        "mes": dt.month,
        "dia": dt.day,
        "dia_semana": dt.weekday(),
        "tramo_horario": tramo,
        "lugar_especifico": lugar,
    }])

    pred_model = pipe.predict(fila)[0]

    print("=== PREDICCIÓN BATCH ===")
    print(fila)
    print(convertir_prediccion(pred_model, bundle))


def probar_online():
    bundle = joblib.load(ONLINE_MODEL_PATH)
    pipe = bundle["pipeline"]

    fecha = "2025-11-22"
    hora = "10:10:00"
    lugar = "Jirón de la Unión"
    tramo = "Mañana"
    tipo_incidente = "Riña entre grupos"

    dt = datetime.fromisoformat(f"{fecha} {hora}")

    hora_decimal = dt.hour + dt.minute / 60 + dt.second / 3600

    fila = pd.DataFrame([{
        "anio": dt.year,
        "mes": dt.month,
        "dia": dt.day,
        "dia_semana": dt.weekday(),
        "hora_decimal": hora_decimal,
        "tramo_horario": tramo,
        "lugar_especifico": lugar,
        "tipo_incidente": tipo_incidente,
    }])

    pred_model = pipe.predict(fila)[0]

    print("\n=== PREDICCIÓN ONLINE ===")
    print(fila)
    print(convertir_prediccion(pred_model, bundle))


if __name__ == "__main__":
    probar_batch()
    probar_online()