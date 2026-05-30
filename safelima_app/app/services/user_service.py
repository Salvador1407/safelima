from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from datetime import timedelta
from app.security import auth
from fastapi import HTTPException, status
from app.repositories import user_repository
from app.schemas.user_schema import CitizenRegisterCreate, UserCreate, UserUpdate

def register(db: Session, objecto: UserCreate):
    return user_repository.create(db, objecto)

def register_citizen(db: Session, objecto: CitizenRegisterCreate):
    if user_repository.get_by_name(db, objecto.username):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El username ya existe",
        )

    if user_repository.get_citizen_by_correo(db, str(objecto.correo)):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El correo ya existe",
        )

    try:
        db_user, db_citizen = user_repository.create_citizen_user(db, objecto)
    except IntegrityError as exc:
        detail = _registration_conflict_detail(exc)
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
        ) from exc
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se pudo registrar ciudadano con los datos enviados",
        ) from exc

    return {
        "user_id": db_user.id,
        "citizen_id": db_citizen.id,
        "username": db_user.username,
        "role": db_user.role,
        "enable": db_user.enable,
        "full_name": db_citizen.full_name,
        "correo": db_citizen.correo,
    }

def _registration_conflict_detail(exc: IntegrityError) -> str:
    error_text = str(exc.orig).lower()

    if "users_username_key" in error_text or "username" in error_text:
        return "El username ya existe"

    if "uq_citizens_correo_lower" in error_text or "correo" in error_text:
        return "El correo ya existe"

    return "Ya existe una cuenta con los datos enviados"

def list_all(db: Session):
    return user_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return user_repository.get_by_id(db, object_id)

def modify(db: Session,
           object_id: int, 
           objecto: UserUpdate):
    return user_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: UserUpdate):
    return user_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return user_repository.delete(db, object_id)

#Funcionalidades
def getUsersCitizen(db: Session):
    return user_repository.getUsersCitizen(db)


 #LOGIN
def login(db: Session, username: str, password: str):
    db_user = user_repository.get_by_name(db, username)

    if not db_user:
        raise HTTPException(status_code=404, detail="El usuario no existe")

    if not db_user.enable:
        raise HTTPException(status_code=401, detail="Usuario no autorizado")


    if not auth.verify_password(password, db_user.password):
        raise HTTPException(
            status_code=401,
            detail="Contraseña incorrecta"
        )

    # 🧠 Si es un ciudadano -> buscar id_citizen
    citizen_id = None
    if db_user.role == "user":
        citizen_id = user_repository.getCitizenID(db, db_user)

    # 🎟️ Generar token de acceso
    access_token = auth.create_access_token({"sub": db_user.username, "role": db_user.role})

    # 🧩 Respuesta según tipo
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "id": db_user.id,
        "citizen_id": citizen_id,
        "role": db_user.role
    }
