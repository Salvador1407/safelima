from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PoliceStationBase(BaseModel):
    nombre: Optional[str] = Field(None, max_length=100)
    direccion: Optional[str] = None
    telefono: Optional[str] = Field(None, max_length=20)
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    distrito: Optional[str] = Field(None, max_length=50)

class PoliceStationCreate(PoliceStationBase):
    nombre: str
    latitud: float
    longitud: float

class PoliceStationUpdate(PoliceStationBase):
    pass

class PoliceStationOut(PoliceStationBase):
    id: int
    fecha_registro: datetime

    class Config:
        from_attributes = True

class PoliceStationNearbyOut(PoliceStationOut):
    distancia_km: float