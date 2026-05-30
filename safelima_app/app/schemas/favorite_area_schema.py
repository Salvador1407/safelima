from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.schemas.grid_schema import GridOut

class FavoriteAreaBase(BaseModel):
    fecha_agregado: Optional[datetime] = None

class FavoriteAreaCreate(BaseModel):
    citizen_id: int
    grid_id: int

class FavoriteAreaOut(FavoriteAreaBase):
    id: int
    citizen_id: int
    grid_id: int
    grid: GridOut

    class Config:
        from_attributes = True