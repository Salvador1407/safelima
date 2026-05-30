from datetime import datetime
from sqlalchemy.orm import Session
from app.models.password_reset_token_model import PasswordResetToken


def create(db: Session, obj: PasswordResetToken):
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_valid_by_code(db: Session, codigo: str):
    return (
        db.query(PasswordResetToken)
        .filter(
            PasswordResetToken.codigo == codigo,
            PasswordResetToken.used == False,
            PasswordResetToken.expires_at > datetime.utcnow()
        )
        .first()
    )


def invalidate_user_tokens(db: Session, user_id: int):
    rows = (
        db.query(PasswordResetToken)
        .filter(
            PasswordResetToken.user_id == user_id,
            PasswordResetToken.used == False,
            PasswordResetToken.expires_at > datetime.utcnow()
        )
        .all()
    )

    for row in rows:
        row.used = True

    db.commit()


def mark_used(db: Session, token_row: PasswordResetToken):
    token_row.used = True
    db.commit()
    db.refresh(token_row)
    return token_row