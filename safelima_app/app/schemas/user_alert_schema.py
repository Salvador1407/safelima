from pydantic import BaseModel
from datetime import datetime
from app.schemas.grid_schema import GridOut
from typing import Optional
from fastapi import Form

class UserAlertBase(BaseModel):
    titulo: Optional[str] = None
    tipo_incidente: Optional[str] = None
    descripcion: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    ruta_foto: Optional[str] = None
    estado: Optional[str] = None
    fecha: Optional[datetime] = None


class UserAlertCreateSchema(BaseModel):
    citizen_id: int
    grid_id: int
    titulo: Optional[str] = None
    tipo_incidente: str
    descripcion: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    ruta_foto: Optional[str] = None
    
class UserAlertCreate(BaseModel):
    citizen_id: int
    grid_id: int
    titulo: Optional[str] = None
    tipo_incidente: str
    descripcion: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    ruta_foto: Optional[str] = None

    @classmethod
    def as_form(
        cls,
        citizen_id: int = Form(...),
        grid_id: int = Form(...),
        titulo: Optional[str] = Form(None),
        tipo_incidente: str = Form(...),
        descripcion: Optional[str] = Form(None),
        nivel_riesgo: Optional[str] = Form(None),
    ):
        return cls(
            citizen_id=citizen_id,
            grid_id=grid_id,
            titulo=titulo,
            tipo_incidente=tipo_incidente,
            descripcion=descripcion,
            nivel_riesgo=nivel_riesgo,
        )


class UserAlertUpdate(BaseModel):
    titulo: Optional[str] = None
    tipo_incidente: Optional[str] = None
    descripcion: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    ruta_foto: Optional[str] = None # Para guardar la URL si se sube foto

    @classmethod
    def as_form(
        cls,
        titulo: Optional[str] = Form(None),
        tipo_incidente: Optional[str] = Form(None),
        descripcion: Optional[str] = Form(None),
        nivel_riesgo: Optional[str] = Form(None),
    ):
        return cls(
            titulo=titulo,
            tipo_incidente=tipo_incidente,
            descripcion=descripcion,
            nivel_riesgo=nivel_riesgo,
        )

class UserAlertUpdateAdmin(BaseModel):
    titulo: Optional[str] = None
    tipo_incidente: Optional[str] = None
    descripcion: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    ruta_foto: Optional[str] = None
    estado: Optional[str] = None

class UserAlertGet(UserAlertBase):
    id: int
    citizen_id: int
    grid_id: int


class UserAlertOut(UserAlertBase):
    id: int
    grid: GridOut
    class Config:
        from_attributes = True
