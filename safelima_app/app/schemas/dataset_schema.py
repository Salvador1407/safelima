from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class DatasetBase(BaseModel):
    nombre: Optional[str] = None
    fuente: Optional[str] = None
    ruta_archivo: Optional[str] = None
    num_registros: Optional[int] = None
    descripcion: Optional[str] = None
    fecha_ingreso: Optional[datetime] = None


class DatasetCreate(DatasetBase):
    pass


class DatasetUpdate(DatasetBase):
    pass

class DatasetGet(DatasetBase):
    id: int


class DatasetOut(DatasetBase):
    id: int

    class Config:
        from_attributes = True
