from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.repositories import favorite_area_repository
from app.schemas.favorite_area_schema import FavoriteAreaCreate

def register(db: Session, objeto: FavoriteAreaCreate):
    existing = favorite_area_repository.get_by_citizen_and_grid(
        db, objeto.citizen_id, objeto.grid_id
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="La zona ya está en favoritos"
        )

    created = favorite_area_repository.create(db, objeto)
    if not created:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se pudo registrar la zona favorita"
        )
    return created

def list_by_citizen(db: Session, citizen_id: int):
    return favorite_area_repository.get_all_by_citizen(db, citizen_id)

def find_by_citizen_and_grid(db: Session, citizen_id: int, grid_id: int):
    return favorite_area_repository.get_by_citizen_and_grid(db, citizen_id, grid_id)

def remove_by_citizen_and_grid(db: Session, citizen_id: int, grid_id: int):
    deleted = favorite_area_repository.delete_by_citizen_and_grid(db, citizen_id, grid_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Zona favorita no encontrada"
        )
    return deleted