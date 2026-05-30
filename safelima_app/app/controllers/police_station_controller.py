from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.police_station_schema import (
    PoliceStationOut,
    PoliceStationCreate,
    PoliceStationUpdate,
    PoliceStationNearbyOut
)
from app.services import police_station_service

router = APIRouter(prefix="/policestations", tags=["Comisarías"])

@router.post("/", response_model=PoliceStationOut, status_code=status.HTTP_201_CREATED)
def create(objeto: PoliceStationCreate, db: Session = Depends(get_db)):
    return police_station_service.register(db, objeto)

@router.get("/", response_model=list[PoliceStationOut])
def get_objects(
    distrito: str | None = Query(None),
    nombre: str | None = Query(None),
    db: Session = Depends(get_db)
):
    return police_station_service.list_all(db, distrito=distrito, nombre=nombre)

@router.get("/nearby", response_model=list[PoliceStationNearbyOut])
def get_nearby(
    lat: float = Query(...),
    lon: float = Query(...),
    limit: int = Query(5, ge=1, le=20),
    max_distance_km: float | None = Query(None, ge=0.1, le=50),
    db: Session = Depends(get_db)
):
    return police_station_service.list_nearby(
        db,
        lat=lat,
        lon=lon,
        limit=limit,
        max_distance_km=max_distance_km
    )

@router.get("/{obj_id}", response_model=PoliceStationOut)
def get_obj(obj_id: int, db: Session = Depends(get_db)):
    objeto = police_station_service.find_by_id(db, obj_id)
    if not objeto:
        raise HTTPException(status_code=404, detail="Police station not found")
    return objeto

@router.patch("/{obj_id}", response_model=PoliceStationOut)
def update(obj_id: int, objeto: PoliceStationUpdate, db: Session = Depends(get_db)):
    updated = police_station_service.patch(db, obj_id, objeto)
    if not updated:
        raise HTTPException(status_code=404, detail="Police station not found")
    return updated