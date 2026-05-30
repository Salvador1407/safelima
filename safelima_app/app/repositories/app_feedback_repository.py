from sqlalchemy.orm import Session
from app.models.app_feedback import AppFeedback
from app.schemas.app_feedback_schema import AppFeedbackCreate, AppFeedbackUpdate

def get_by_citizen_id(db: Session, citizen_id: int):
    return db.query(AppFeedback).filter(AppFeedback.citizen_id == citizen_id).first()

def create(db: Session, objeto: AppFeedbackCreate):
    db_object = AppFeedback(**objeto.model_dump())
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def update(db: Session, db_object: AppFeedback, data: AppFeedbackUpdate):
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_object, key, value)

    db.commit()
    db.refresh(db_object)
    return db_object

def get_all(db: Session):
    return db.query(AppFeedback).order_by(AppFeedback.fecha.desc()).all()