from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.citizen_schema import CitizenOut
from app.schemas.user_schema import (
    CitizenRegisterCreate,
    CitizenRegisterOut,
    UserOut,
    UserCreate,
    UserUpdate,
    UserGetEnable,
    UserGetLogin,
)
from app.services import user_service, citizen_service
from app.schemas.user_schema import TokenLogin
from app.schemas.user_schema import UserLogin

from app.schemas.user_schema import ForgotPasswordRequest, ResetPasswordRequest
from app.services import user_recovery_service

router = APIRouter(prefix="/users", tags=["Usuarios"])

#@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
#def create(objecto: UserCreate, db: Session = Depends(get_db)):
#    user_service.register(db, objecto)
    
@router.post("/", response_model=UserOut)
def create(objecto: UserCreate, db: Session = Depends(get_db)):
    return user_service.register(db, objecto)

@router.post(
    "/register-citizen",
    response_model=CitizenRegisterOut,
    status_code=status.HTTP_201_CREATED,
)
def register_citizen(objecto: CitizenRegisterCreate, db: Session = Depends(get_db)):
    return user_service.register_citizen(db, objecto)

@router.get("/", response_model=list[UserOut])
def get_objects(db: Session = Depends(get_db)):
    return user_service.list_all(db)

@router.get("/{object_id}", response_model=UserOut)
def get_obj(object_id: int, db: Session = Depends(get_db)):
    Objecto = user_service.find_by_id(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, 
                            detail="Object not found")
    return Objecto

@router.put("/{object_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(object_id: int, objecto: UserUpdate, db: Session = Depends(get_db)):
    user_service.modify(db, object_id, objecto)
    
@router.patch("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: UserUpdate, db: Session = Depends(get_db)):
    updated = user_service.patch(db, Obj_id, objecto)
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")

@router.delete("/{object_id}")
def delete(object_id: int, db: Session = Depends(get_db)):
    return user_service.remove(db, object_id)


#Funcionalidades Users
#Obtienes todos los usuarios filtrados como ciudadanos, exceptuando los usuarios admins 
@router.get("/UsersCitizen/", response_model=list[UserGetEnable])
def get_Users_Student(db: Session = Depends(get_db)):
    return user_service.getUsersCitizen(db)

@router.get("/UsersDetail/{object_id}", response_model=CitizenOut)
def get_Users_Detail(object_id: int, db: Session = Depends(get_db)):
    Objecto = citizen_service.getUsersDetail(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

#LOGIN
@router.post("/login/", response_model=TokenLogin)
def login(user: UserLogin, db: Session = Depends(get_db)):
    return user_service.login(db, user.username, user.password)

@router.get("/getUserLogin/{object_id}", response_model=UserGetLogin)
def get_obj(object_id: int, db: Session = Depends(get_db)):
    Objecto = user_service.find_by_id(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, 
                            detail="Object not found")
    return Objecto

#FORGOT & RESET PASSWORD
@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    return user_recovery_service.request_password_reset(db, payload.correo)


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    return user_recovery_service.reset_password(
        db,
        payload.codigo,
        payload.new_password
    )
