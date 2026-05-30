from sqlalchemy.orm import Session
from app.repositories import dataset_repository
from app.schemas.dataset_schema import DatasetCreate, DatasetUpdate


def register(db: Session, objecto: DatasetCreate):
    return dataset_repository.create(db, objecto)


def list_all(db: Session):
    return dataset_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return dataset_repository.get_by_id(db, object_id)


def modify(db: Session, object_id: int, objecto: DatasetUpdate):
    return dataset_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: DatasetUpdate):
    return dataset_repository.patch(db, object_id, objecto)


def remove(db: Session, object_id: int):
    return dataset_repository.delete(db, object_id)
