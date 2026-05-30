from sqlalchemy.orm import Session
from app.repositories import prediction_grid_repository
from app.schemas.prediction_grid_schema import PredictionGridCreate, PredictionGridUpdate


def register(db: Session, objecto: PredictionGridCreate):
    return prediction_grid_repository.create(db, objecto)


def list_all(db: Session):
    return prediction_grid_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return prediction_grid_repository.get_by_id(db, object_id)


def modify(db: Session, object_id: int, objecto: PredictionGridUpdate):
    return prediction_grid_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: PredictionGridUpdate):
    return prediction_grid_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return prediction_grid_repository.delete(db, object_id)
