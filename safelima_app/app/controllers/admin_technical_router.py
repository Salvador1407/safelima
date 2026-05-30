from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.technical_status_schema import TechnicalDashboardOut
from app.services import technical_status_service

router = APIRouter(prefix="/admin/technical", tags=["Panel Técnico"])

@router.get("/status", response_model=TechnicalDashboardOut)
def get_technical_status(db: Session = Depends(get_db)):
    return technical_status_service.get_technical_dashboard(db)