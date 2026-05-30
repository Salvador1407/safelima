from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.favorite_area_schema import FavoriteAreaOut, FavoriteAreaCreate
from app.services import favorite_area_service

router = APIRouter(prefix="/favorites", tags=["Zonas Favoritas"])

@router.post("/", response_model=FavoriteAreaOut, status_code=status.HTTP_201_CREATED)
def create(objeto: FavoriteAreaCreate, db: Session = Depends(get_db)):
    return favorite_area_service.register(db, objeto)

@router.get("/citizen/{citizen_id}", response_model=list[FavoriteAreaOut])
def get_by_citizen(citizen_id: int, db: Session = Depends(get_db)):
    return favorite_area_service.list_by_citizen(db, citizen_id)

@router.get("/citizen/{citizen_id}/grid/{grid_id}", response_model=FavoriteAreaOut)
def get_by_citizen_and_grid(citizen_id: int, grid_id: int, db: Session = Depends(get_db)):
    favorito = favorite_area_service.find_by_citizen_and_grid(db, citizen_id, grid_id)
    if not favorito:
        raise HTTPException(status_code=404, detail="Zona no marcada como favorita")
    return favorito

@router.delete("/citizen/{citizen_id}/grid/{grid_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_by_citizen_and_grid(citizen_id: int, grid_id: int, db: Session = Depends(get_db)):
    favorite_area_service.remove_by_citizen_and_grid(db, citizen_id, grid_id)