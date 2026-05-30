from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class MLModelBase(BaseModel):
    nombre_modelo: Optional[str] = None
    version: Optional[str] = None
    ruta_modelo: Optional[str] = None
    precision: Optional[float] = None
    accuracy: Optional[float] = None
    recall: Optional[float] = None
    f1: Optional[float] = None
    auc: Optional[float] = None
    fecha_entrenamiento: Optional[datetime] = None


class MLModelCreate(MLModelBase):
    dataset_id: int


class MLModelUpdate(MLModelBase):
    pass

class MLModelGet(MLModelBase):
    id: int
    dataset_id: int


class MLModelOut(MLModelBase):
    id: int
    dataset_id: int
    class Config:
        from_attributes = True
