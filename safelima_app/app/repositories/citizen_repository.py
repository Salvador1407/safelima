from sqlalchemy.orm import Session
from app.models.citizen_model import Citizen
from app.schemas.citizen_schema import CitizenCreate, CitizenUpdate


def create(db: Session, objeto: CitizenCreate):
    db_object = Citizen(
        user_id=objeto.user_id,
        full_name=objeto.full_name,
        correo=objeto.correo,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(Citizen).all()


def get_by_id(db: Session, object_id: int):
    return db.query(Citizen).filter(Citizen.id == object_id).first()


def update(db: Session, object_id: int, objeto: CitizenUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.full_name = objeto.full_name
        db_object.correo = objeto.correo
        db.commit()
        db.refresh(db_object)
    return db_object

def patch(db: Session, object_id: int, objeto: CitizenUpdate):
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

#Funcionalidades
def getUsersDetail(db: Session, user_id: int):
    return db.query(Citizen).filter(Citizen.user_id == user_id).first()
