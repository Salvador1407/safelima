from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.repositories import app_feedback_repository, citizen_repository
from app.schemas.app_feedback_schema import AppFeedbackCreate, AppFeedbackUpdate

def register_feedback(db: Session, objeto: AppFeedbackCreate):
    citizen = citizen_repository.get_by_id(db, objeto.citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ciudadano no encontrado"
        )

    existing = app_feedback_repository.get_by_citizen_id(db, objeto.citizen_id)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El usuario ya calificó la app"
        )

    return app_feedback_repository.create(db, objeto)

def upsert_feedback(db: Session, citizen_id: int, data: AppFeedbackUpdate):
    existing = app_feedback_repository.get_by_citizen_id(db, citizen_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No existe feedback para este usuario"
        )

    return app_feedback_repository.update(db, existing, data)

def get_all_feedback(db: Session):
    return app_feedback_repository.get_all(db)

def get_feedback_by_citizen(db: Session, citizen_id: int):
    feedback = app_feedback_repository.get_by_citizen_id(db, citizen_id)
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback no encontrado"
        )
    return feedback