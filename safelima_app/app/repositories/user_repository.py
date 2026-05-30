from sqlalchemy.orm import Session

from app.models.citizen_model import Citizen
from app.models.user_model import User
from app.schemas.user_schema import CitizenRegisterCreate, UserCreate, UserUpdate
from app.security.auth import hash_password
from sqlalchemy import func


def create(db: Session, objeto: UserCreate):
    db_object = User(
        username=objeto.username,
        password=hash_password(objeto.password),
        enable=True if objeto.enable is None else objeto.enable,
        role="user",
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def create_citizen_user(db: Session, objeto: CitizenRegisterCreate):
    db_user = User(
        username=objeto.username,
        password=hash_password(objeto.password),
        enable=True,
        role="user",
    )
    db.add(db_user)

    try:
        db.flush()

        db_citizen = Citizen(
            user_id=db_user.id,
            full_name=objeto.full_name,
            correo=str(objeto.correo).strip().lower(),
        )
        db.add(db_citizen)
        db.commit()
        db.refresh(db_user)
        db.refresh(db_citizen)
        return db_user, db_citizen
    except Exception:
        db.rollback()
        raise


def get(db: Session):
    return db.query(User).all()


def get_by_id(db: Session, object_id: int):
    return db.query(User).filter(User.id == object_id).first()


def update(db: Session, object_id: int, objeto: UserUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.username = objeto.username
        if objeto.password is not None:
            db_object.password = hash_password(objeto.password)
        db_object.enable = objeto.enable
        db.commit()
        db.refresh(db_object)
    return db_object


def patch(db: Session, object_id: int, objeto: UserUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        if key == "password":
            if value is not None:
                setattr(db_object, key, hash_password(value))
        else:
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


def getUsersCitizen(db: Session):
    return db.query(User).filter(User.role == "user").all()


def get_by_name(db: Session, nameuser: str):
    return db.query(User).filter(User.username == nameuser).first()


def get_citizen_by_correo(db: Session, correo: str):
    correo_normalizado = correo.strip().lower()
    return (
        db.query(Citizen)
        .filter(func.lower(func.trim(Citizen.correo)) == correo_normalizado)
        .first()
    )


def getCitizenID(db: Session, user: User) -> int | None:
    result = db.query(Citizen.id).filter(Citizen.user_id == user.id).first()
    return result[0] if result else None
