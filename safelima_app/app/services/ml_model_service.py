from sqlalchemy.orm import Session
from app.repositories import ml_model_repository
from app.schemas.ml_model_schema import MLModelCreate, MLModelUpdate


def register(db: Session, objecto: MLModelCreate):
    return ml_model_repository.create(db, objecto)


def list_all(db: Session):
    return ml_model_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return ml_model_repository.get_by_id(db, object_id)


def modify(db: Session, object_id: int, objecto: MLModelUpdate):
    return ml_model_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: MLModelUpdate):
    return ml_model_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return ml_model_repository.delete(db, object_id)
