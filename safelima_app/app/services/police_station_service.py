from sqlalchemy.orm import Session
from app.repositories import police_station_repository
from app.schemas.police_station_schema import PoliceStationCreate, PoliceStationUpdate

def register(db: Session, objeto: PoliceStationCreate):
    return police_station_repository.create(db, objeto)

def list_all(db: Session, distrito: str | None = None, nombre: str | None = None):
    return police_station_repository.get(db, distrito=distrito, nombre=nombre)

def find_by_id(db: Session, object_id: int):
    return police_station_repository.get_by_id(db, object_id)

def patch(db: Session, object_id: int, objeto: PoliceStationUpdate):
    return police_station_repository.patch(db, object_id, objeto)

def list_nearby(db: Session, lat: float, lon: float, limit: int = 5, max_distance_km: float | None = None):
    return police_station_repository.get_nearby(db, lat, lon, limit, max_distance_km)