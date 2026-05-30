from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import (
    zone_review_repository,
    citizen_repository,
    grid_repository,
    review_like_repository
)
from app.schemas.zone_review_schema import ZoneReviewCreate, ZoneReviewUpdate


def register(db: Session, objeto: ZoneReviewCreate):
    citizen = citizen_repository.get_by_id(db, objeto.citizen_id)
    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")

    grid = grid_repository.get_by_id(db, objeto.grid_id)
    if not grid:
        raise HTTPException(status_code=404, detail="Grid not found")

    return zone_review_repository.create(db, objeto)


def list_all(db: Session):
    return zone_review_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return zone_review_repository.get_by_id(db, object_id)


def find_by_grid_id(db: Session, grid_id: int):
    return zone_review_repository.get_by_grid_id(db, grid_id)

def get_summary_by_grid(db: Session, grid_id: int, citizen_id: int | None = None):
    reviews = zone_review_repository.get_by_grid_id(db, grid_id)

    total_reviews = len(reviews)
    promedio = (
        sum(r.calificacion for r in reviews) / total_reviews
        if total_reviews > 0 else 0
    )

    result_reviews = []

    for r in reviews:
        likes_count = review_like_repository.count_by_review(db, r.id)

        is_liked = False
        if citizen_id is not None:
            existing_like = review_like_repository.get_by_citizen_and_review(
                db, citizen_id, r.id
            )
            is_liked = existing_like is not None

        item = {
            "id": r.id,
            "citizen_id": r.citizen_id,
            "grid_id": r.grid_id,
            "calificacion": r.calificacion,
            "comentario": r.comentario,
            "fecha_publicacion": r.fecha_publicacion,
            "citizen_name": r.citizen.full_name if r.citizen else None,
            "likes_count": likes_count,
            "is_liked": is_liked,
        }
        result_reviews.append(item)

    return {
        "grid_id": grid_id,
        "promedio_calificacion": promedio,
        "total_reviews": total_reviews,
        "reviews": result_reviews,
    }


def get_grid_summary(db: Session, grid_id: int):
    return zone_review_repository.get_summary_by_grid_id(db, grid_id)


def patch(db: Session, object_id: int, objeto: ZoneReviewUpdate):
    return zone_review_repository.patch(db, object_id, objeto)


def remove(db: Session, object_id: int):
    return zone_review_repository.delete(db, object_id)