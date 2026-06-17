from sqlalchemy.orm import Session
from app.repositories import prediction_grid_repository
from app.schemas.prediction_grid_schema import PredictionGridCreate, PredictionGridUpdate
from app.services.time_slot_service import get_time_slot, validate_time_slot


def register(db: Session, objecto: PredictionGridCreate):
    return prediction_grid_repository.create(db, objecto)


def list_all(db: Session):
    return prediction_grid_repository.get(db)


def list_by_tramo(db: Session, tramo_horario: str):
    tramo = validate_time_slot(tramo_horario)
    return prediction_grid_repository.get_by_tramo(db, tramo)


def list_current(db: Session):
    return list_by_tramo(db, get_time_slot())


def find_by_id(db: Session, object_id: int):
    return prediction_grid_repository.get_by_id(db, object_id)


def upsert_prediction(
    db: Session,
    *,
    grid_id: int,
    tramo_horario: str,
    score_riesgo: int,
    nivel_riesgo: str,
):
    tramo = validate_time_slot(tramo_horario)
    return prediction_grid_repository.upsert_by_grid_and_tramo(
        db,
        grid_id=grid_id,
        tramo_horario=tramo,
        score_riesgo=score_riesgo,
        nivel_riesgo=nivel_riesgo,
    )


def modify(db: Session, object_id: int, objecto: PredictionGridUpdate):
    return prediction_grid_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: PredictionGridUpdate):
    return prediction_grid_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return prediction_grid_repository.delete(db, object_id)
