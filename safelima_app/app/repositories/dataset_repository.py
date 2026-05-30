from sqlalchemy.orm import Session
from app.models.dataset_model import Dataset
from app.schemas.dataset_schema import DatasetCreate, DatasetUpdate


def create(db: Session, objeto: DatasetCreate):
    db_object = Dataset(
        nombre=objeto.nombre,
        fuente=objeto.fuente,
        ruta_archivo=objeto.ruta_archivo,
        num_registros=objeto.num_registros,
        descripcion=objeto.descripcion,
        fecha_ingreso=objeto.fecha_ingreso,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(Dataset).all()


def get_by_id(db: Session, object_id: int):
    return db.query(Dataset).filter(Dataset.id == object_id).first()


def update(db: Session, object_id: int, objeto: DatasetUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.nombre = objeto.nombre
        db_object.fuente = objeto.fuente
        db_object.ruta_archivo = objeto.ruta_archivo
        db_object.num_registros = objeto.num_registros
        db_object.descripcion = objeto.descripcion
        db_object.fecha_ingreso = objeto.fecha_ingreso
        db.commit()
        db.refresh(db_object)
    return db_object


def patch(db: Session, object_id: int, objeto: DatasetUpdate):
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
