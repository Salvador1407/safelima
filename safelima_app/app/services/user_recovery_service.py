from datetime import datetime, timedelta
import random
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.password_reset_token_model import PasswordResetToken
from app.models.citizen_model import Citizen
from app.models.user_model import User
from app.repositories import password_reset_repository, user_repository
from app.security.auth import hash_password
from app.services.email_service import send_reset_email

def _generate_otp_code() -> str:
    return str(random.randint(100000, 999999))

def request_password_reset(db: Session, correo: str):
    citizen = db.query(Citizen).filter(Citizen.correo == correo).first()

    # Respuesta genérica por seguridad
    if not citizen or not citizen.user_id:
        raise HTTPException(status_code=404, detail="Correo no registrado")

    user = db.query(User).filter(User.id == citizen.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # Invalidar códigos/tokens anteriores del usuario
    password_reset_repository.invalidate_user_tokens(db, user.id)

    otp_code = _generate_otp_code()
    expires_at = datetime.utcnow() + timedelta(minutes=15)

    token_row = PasswordResetToken(
        user_id=user.id,
        codigo=otp_code,
        expires_at=expires_at,
        used=False,
        created_at=datetime.utcnow()
    )

    password_reset_repository.create(db, token_row)

    # Ahora enviamos el código, no un link
    send_reset_email(correo, otp_code)

    return {
        "message": "Si el correo existe, se enviaron instrucciones de recuperación."
    }


def reset_password(db: Session, codigo: str, new_password: str):
    token_row = password_reset_repository.get_valid_by_code(db, codigo)

    if not token_row:
        raise HTTPException(status_code=400, detail="Código inválido o expirado")

    user = user_repository.get_by_id(db, token_row.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.password = hash_password(new_password)
    db.commit()
    db.refresh(user)

    password_reset_repository.mark_used(db, token_row)

    return {"message": "Contraseña actualizada correctamente"}