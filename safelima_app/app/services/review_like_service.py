from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import (
    review_like_repository,
    citizen_repository,
    zone_review_repository,
)
from app.schemas.review_like_schema import ReviewLikeCreate


def toggle_like(db: Session, objeto: ReviewLikeCreate):
    citizen = citizen_repository.get_by_id(db, objeto.citizen_id)
    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")

    review = zone_review_repository.get_by_id(db, objeto.review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    existing_like = review_like_repository.get_by_citizen_and_review(
        db, objeto.citizen_id, objeto.review_id
    )

    if existing_like:
        review_like_repository.delete_like(db, objeto.citizen_id, objeto.review_id)
        likes_count = review_like_repository.count_by_review(db, objeto.review_id)
        return {
            "liked": False,
            "likes_count": likes_count,
            "review_id": objeto.review_id,
        }

    review_like_repository.create(db, objeto)
    likes_count = review_like_repository.count_by_review(db, objeto.review_id)
    return {
        "liked": True,
        "likes_count": likes_count,
        "review_id": objeto.review_id,
    }