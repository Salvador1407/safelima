from sqlalchemy.orm import Session
from app.models.grid_model import Grid
from app.schemas.grid_schema import GridCreate, GridUpdate


def create(db: Session, objeto: GridCreate):
    db_object = Grid(
        nombre=objeto.nombre,
        grid_lat_idx=objeto.grid_lat_idx,
        grid_lon_idx=objeto.grid_lon_idx,
        centro_lat=objeto.centro_lat,
        centro_lon=objeto.centro_lon,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(Grid).all()


def get_by_id(db: Session, object_id: int):
    return db.query(Grid).filter(Grid.id == object_id).first()


def update(db: Session, object_id: int, objeto: GridUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.nombre = objeto.nombre
        db_object.grid_lat_idx = objeto.grid_lat_idx
        db_object.grid_lon_idx = objeto.grid_lon_idx
        db_object.centro_lat = objeto.centro_lat
        db_object.centro_lon = objeto.centro_lon
        db.commit()
        db.refresh(db_object)
    return db_object

def patch(db: Session, object_id: int, objeto: GridUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_object, key, value)

    db.commit()
    db.refresh(db_object)
    return db_object


def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object
