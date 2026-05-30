from pydantic import BaseModel
from datetime import datetime
from app.schemas.grid_schema import GridOut
from typing import Optional

class PredictionGridBase(BaseModel):
    score_riesgo: Optional[int] = None
    tramo_horario: Optional[str] = None
    nivel_riesgo: Optional[str] = None
    fecha_prediccion: Optional[datetime] = None


class PredictionGridCreate(PredictionGridBase):
    grid_id: int


class PredictionGridUpdate(PredictionGridBase):
    pass


class PredictionGridOut(PredictionGridBase):
    id: int
    grid: GridOut

    class Config:
        from_attributes = True