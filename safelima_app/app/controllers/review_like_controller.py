from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.review_like_schema import ReviewLikeCreate, ReviewLikeToggleResponse
from app.services import review_like_service

router = APIRouter(prefix="/reviewlikes", tags=["Likes de Reseñas"])


@router.post("/", response_model=ReviewLikeToggleResponse, status_code=status.HTTP_200_OK)
def toggle_like(objeto: ReviewLikeCreate, db: Session = Depends(get_db)):
    return review_like_service.toggle_like(db, objeto)
