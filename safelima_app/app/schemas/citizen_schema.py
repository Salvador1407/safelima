from pydantic import BaseModel, EmailStr
from typing import List, Optional
from app.schemas.user_schema import UserOut

class CitizenBase(BaseModel):
    full_name: Optional[str] = None
    correo: Optional[EmailStr] = None


class CitizenCreate(CitizenBase):
    user_id: int

class CitizenGet(CitizenBase):
    id: int
    user_id: int

class CitizenUpdate(CitizenBase):
    pass

class CitizenOut(CitizenBase):
    id: int
    user: UserOut #igual a los objetos de model
    class Config:
        from_attributes = True
