from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.app_feedback_schema import (
    AppFeedbackOut,
    AppFeedbackCreate,
    AppFeedbackUpdate
)
from app.services import app_feedback_service

router = APIRouter(prefix="/appfeedback", tags=["Feedback de la App"])

@router.post("/", response_model=AppFeedbackOut, status_code=status.HTTP_201_CREATED)
def create(objeto: AppFeedbackCreate, db: Session = Depends(get_db)):
    return app_feedback_service.register_feedback(db, objeto)

@router.get("/", response_model=list[AppFeedbackOut])
def get_objects(db: Session = Depends(get_db)):
    return app_feedback_service.get_all_feedback(db)

@router.get("/citizen/{citizen_id}", response_model=AppFeedbackOut)
def get_by_citizen(citizen_id: int, db: Session = Depends(get_db)):
    return app_feedback_service.get_feedback_by_citizen(db, citizen_id)

@router.patch("/citizen/{citizen_id}", response_model=AppFeedbackOut)
def update_by_citizen(
    citizen_id: int,
    objeto: AppFeedbackUpdate,
    db: Session = Depends(get_db)
):
    return app_feedback_service.upsert_feedback(db, citizen_id, objeto)