from sqlalchemy.orm import Session
from app.models.favorite_area_model import FavoriteArea
from app.schemas.favorite_area_schema import FavoriteAreaCreate
from sqlalchemy.exc import IntegrityError

def create(db: Session, objeto: FavoriteAreaCreate):
    db_object = FavoriteArea(
        citizen_id=objeto.citizen_id,
        grid_id=objeto.grid_id,
    )
    db.add(db_object)
    try:
        db.commit()
        db.refresh(db_object)
        return db_object
    except IntegrityError:
        db.rollback()
        return None

def get_all_by_citizen(db: Session, citizen_id: int):
    return db.query(FavoriteArea).filter(FavoriteArea.citizen_id == citizen_id).all()

def get_by_citizen_and_grid(db: Session, citizen_id: int, grid_id: int):
    return db.query(FavoriteArea).filter(
        FavoriteArea.citizen_id == citizen_id,
        FavoriteArea.grid_id == grid_id
    ).first()

def delete_by_citizen_and_grid(db: Session, citizen_id: int, grid_id: int):
    db_object = get_by_citizen_and_grid(db, citizen_id, grid_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object