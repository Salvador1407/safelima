from sqlalchemy.orm import Session
from app.repositories import grid_repository
from app.schemas.grid_schema import GridCreate, GridUpdate


def register(db: Session, objecto: GridCreate):
    return grid_repository.create(db, objecto)


def list_all(db: Session):
    return grid_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return grid_repository.get_by_id(db, object_id)


def modify(db: Session, object_id: int, objecto: GridUpdate):
    return grid_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: GridUpdate):
    return grid_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return grid_repository.delete(db, object_id)
