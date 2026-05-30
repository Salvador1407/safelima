from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


class UserBase(BaseModel):
    username: Optional[str] = None
    enable: Optional[bool] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(UserBase):
    password: Optional[str] = None


class UserEnable(BaseModel):
    enable: bool


class UserGetEnable(UserBase):
    id: int
    role: Optional[str] = None

    class Config:
        from_attributes = True


class UserGetLogin(BaseModel):
    id: int
    username: str

    class Config:
        from_attributes = True


class UserOut(UserBase):
    id: int
    role: Optional[str] = None

    class Config:
        from_attributes = True


class CitizenRegisterCreate(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)
    full_name: str = Field(..., min_length=1)
    correo: EmailStr

    @field_validator("username", "full_name")
    @classmethod
    def not_blank(cls, value: str) -> str:
        if not value or not value.strip():
            raise ValueError("Field is required")
        return value.strip()

    @field_validator("password")
    @classmethod
    def password_not_blank(cls, value: str) -> str:
        if not value or not value.strip():
            raise ValueError("Field is required")
        return value
    
    @field_validator("correo")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        return str(value).strip().lower()


class CitizenRegisterOut(BaseModel):
    user_id: int
    citizen_id: int
    username: str
    role: str
    enable: bool
    full_name: str
    correo: EmailStr


class UserLogin(BaseModel):
    username: str
    password: str


class TokenLogin(BaseModel):
    access_token: str
    token_type: str
    id: int
    citizen_id: int | None = None
    role: str


class ForgotPasswordRequest(BaseModel):
    correo: EmailStr


class ResetPasswordRequest(BaseModel):
    codigo: str
    new_password: str = Field(..., min_length=4, max_length=100)
