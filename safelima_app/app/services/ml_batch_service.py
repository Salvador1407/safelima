import logging
from datetime import datetime

from sqlalchemy.orm import Session

from app.repositories import grid_repository
from app.services import ml_inference_service, ml_model_loader_service, prediction_grid_service
from app.services.time_slot_service import TIME_SLOTS, now_in_app_timezone


logger = logging.getLogger(__name__)


def run_batch_predictions(db: Session, fecha_prediccion: datetime | None = None) -> dict:
    ml_model_loader_service.get_batch_bundle()
    prediction_datetime = fecha_prediccion or now_in_app_timezone()
    grids = grid_repository.get(db)

    grids_processed = 0
    predictions_updated = 0
    errors: list[str] = []

    for grid in grids:
        if not grid.nombre:
            errors.append(f"Grid {grid.id} no tiene nombre")
            continue

        grids_processed += 1

        for tramo_horario in TIME_SLOTS:
            try:
                prediction = ml_inference_service.predict_batch(
                    fecha=prediction_datetime,
                    lugar=grid.nombre,
                    tramo=tramo_horario,
                )
                prediction_grid_service.upsert_prediction(
                    db=db,
                    grid_id=grid.id,
                    tramo_horario=tramo_horario,
                    score_riesgo=prediction["score_riesgo"],
                    nivel_riesgo=prediction["nivel_riesgo"],
                )
                predictions_updated += 1
            except Exception as exc:
                db.rollback()
                message = f"Grid {grid.id} tramo {tramo_horario}: {exc}"
                errors.append(message)
                logger.exception("Error en predicción batch: %s", message)

    return {
        "grids_processed": grids_processed,
        "predictions_updated": predictions_updated,
        "errors": errors,
        "ran_at": now_in_app_timezone(),
        "tramo_horarios": list(TIME_SLOTS),
    }
