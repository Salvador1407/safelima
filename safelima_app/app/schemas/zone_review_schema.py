from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ZoneReviewBase(BaseModel):
    calificacion: int = Field(..., ge=1, le=5)
    comentario: str = Field(..., min_length=1)


class ZoneReviewCreate(ZoneReviewBase):
    citizen_id: int
    grid_id: int


class ZoneReviewUpdate(BaseModel):
    calificacion: Optional[int] = Field(None, ge=1, le=5)
    comentario: Optional[str] = Field(None, min_length=1)


class ZoneReviewOut(BaseModel):
    id: int
    citizen_id: int
    grid_id: int
    calificacion: int
    comentario: str
    fecha_publicacion: datetime
    citizen_name: Optional[str] = None
    likes_count: int = 0
    is_liked: bool = False

    class Config:
        from_attributes = True


class ZoneReviewSummary(BaseModel):
    grid_id: int
    total_reviews: int
    promedio_calificacion: float
    reviews: list[ZoneReviewOut]