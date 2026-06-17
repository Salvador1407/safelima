from sqlalchemy.orm import Session

from app.repositories import safe_route_repository
from app.services.time_slot_service import get_time_slot


def _get_current_time_slot() -> str:
    return get_time_slot()


def _risk_weight(nivel_riesgo: str) -> int:
    nivel = (nivel_riesgo or "").lower()

    if nivel == "alto":
        return 12
    if nivel == "medio":
        return 4
    if nivel == "bajo":
        return 1
    return 0


def evaluate_route_risk(
    db: Session,
    coordinates: list[list[float]],
) -> dict:
    """
    coordinates viene como [[lon, lat], [lon, lat], ...]
    """
    risk_score = 0.0
    danger_count = 0
    medium_count = 0
    low_count = 0

    tramo_actual = _get_current_time_slot()
    sampled = coordinates[::3] if len(coordinates) > 3 else coordinates

    visited_prediction_ids: set[int] = set()

    for lon, lat in sampled:
        nearby_predictions = safe_route_repository.get_predictions_near_point(
            db=db,
            lat=lat,
            lon=lon,
            tramo_horario=tramo_actual,
            radius_km=0.15,
        )

        for prediction in nearby_predictions:
            if prediction.id in visited_prediction_ids:
                continue

            visited_prediction_ids.add(prediction.id)

            nivel = (prediction.nivel_riesgo or "").lower()
            risk_score += _risk_weight(nivel)

            if nivel == "alto":
                danger_count += 1
            elif nivel == "medio":
                medium_count += 1
            elif nivel == "bajo":
                low_count += 1

    return {
        "risk_score": risk_score,
        "danger_zones_crossed": danger_count,
        "medium_zones_crossed": medium_count,
        "low_zones_crossed": low_count,
        "tramo_horario_evaluado": tramo_actual,
    }
