from sqlalchemy.orm import Session
from sqlalchemy import func, asc
from app.models.police_stations import PoliceStation
from app.schemas.police_station_schema import PoliceStationCreate, PoliceStationUpdate

def create(db: Session, objeto: PoliceStationCreate):
    db_object = PoliceStation(**objeto.model_dump())
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session, distrito: str | None = None, nombre: str | None = None):
    query = db.query(PoliceStation)

    if distrito:
        query = query.filter(PoliceStation.distrito.ilike(f"%{distrito}%"))

    if nombre:
        query = query.filter(PoliceStation.nombre.ilike(f"%{nombre}%"))

    return query.order_by(PoliceStation.nombre.asc()).all()

def get_by_id(db: Session, object_id: int):
    return db.query(PoliceStation).filter(PoliceStation.id == object_id).first()

def patch(db: Session, object_id: int, objeto: PoliceStationUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_object, key, value)

    db.commit()
    db.refresh(db_object)
    return db_object

def get_nearby(db: Session, lat: float, lon: float, limit: int = 5, max_distance_km: float | None = None):
    distance_expr = (
        func.sqrt(
            func.pow(PoliceStation.latitud - lat, 2) +
            func.pow(PoliceStation.longitud - lon, 2)
        ) * 111
    )

    query = db.query(PoliceStation, distance_expr.label("distancia_km"))

    if max_distance_km is not None:
        query = query.filter(distance_expr <= max_distance_km)

    rows = query.order_by(asc("distancia_km")).limit(limit).all()

    result = []
    for station, distancia_km in rows:
        station.distancia_km = round(float(distancia_km), 2)
        result.append(station)

    return result