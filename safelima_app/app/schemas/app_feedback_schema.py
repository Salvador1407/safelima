from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class AppFeedbackBase(BaseModel):
    estrellas: int = Field(..., ge=1, le=5)
    comentario: Optional[str] = Field(None, max_length=500)

class AppFeedbackCreate(AppFeedbackBase):
    citizen_id: int

class AppFeedbackUpdate(BaseModel):
    estrellas: Optional[int] = Field(None, ge=1, le=5)
    comentario: Optional[str] = Field(None, max_length=500)

class AppFeedbackOut(AppFeedbackBase):
    id: int
    citizen_id: int
    fecha: datetime

    class Config:
        from_attributes = True