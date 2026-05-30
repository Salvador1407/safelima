from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.review_likes import ReviewLike
from app.schemas.review_like_schema import ReviewLikeCreate


def create(db: Session, objeto: ReviewLikeCreate):
    db_object = ReviewLike(**objeto.dict())
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get_by_citizen_and_review(db: Session, citizen_id: int, review_id: int):
    return (
        db.query(ReviewLike)
        .filter(
            ReviewLike.citizen_id == citizen_id,
            ReviewLike.review_id == review_id,
        )
        .first()
    )


def delete_like(db: Session, citizen_id: int, review_id: int):
    db_object = get_by_citizen_and_review(db, citizen_id, review_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object


def count_by_review(db: Session, review_id: int) -> int:
    return (
        db.query(func.count(ReviewLike.id))
        .filter(ReviewLike.review_id == review_id)
        .scalar()
    ) or 0