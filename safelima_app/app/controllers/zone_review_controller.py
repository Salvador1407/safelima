from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.zone_review_schema import (
    ZoneReviewOut,
    ZoneReviewCreate,
    ZoneReviewUpdate,
    ZoneReviewSummary,
)
from app.services import zone_review_service

router = APIRouter(prefix="/zonereviews", tags=["Reseñas de Zonas"])


def build_zone_review_out(review, current_citizen_id: int = 1) -> ZoneReviewOut:
    return ZoneReviewOut(
        id=review.id,
        citizen_id=review.citizen_id,
        grid_id=review.grid_id,
        calificacion=review.calificacion,
        comentario=review.comentario,
        fecha_publicacion=review.fecha_publicacion,
        citizen_name=review.citizen.full_name if review.citizen else None,
        likes_count=len(review.likes) if review.likes else 0,
        is_liked=any(
            like.citizen_id == current_citizen_id for like in (review.likes or [])
        ),
    )


@router.post("/", response_model=ZoneReviewOut, status_code=status.HTTP_201_CREATED)
def create(objeto: ZoneReviewCreate, db: Session = Depends(get_db)):
    review = zone_review_service.register(db, objeto)
    return build_zone_review_out(review)


@router.get("/", response_model=list[ZoneReviewOut])
def get_objects(db: Session = Depends(get_db)):
    reviews = zone_review_service.list_all(db)
    return [build_zone_review_out(r) for r in reviews]


@router.get("/{obj_id}", response_model=ZoneReviewOut)
def get_obj(obj_id: int, db: Session = Depends(get_db)):
    objeto = zone_review_service.find_by_id(db, obj_id)
    if not objeto:
        raise HTTPException(status_code=404, detail="Review not found")
    return build_zone_review_out(objeto)


@router.get("/grid/{grid_id}", response_model=ZoneReviewSummary)
def get_reviews_by_grid(
        grid_id: int,
        citizen_id: int | None = Query(None),
        db: Session = Depends(get_db)
    ):
        return zone_review_service.get_summary_by_grid(db, grid_id, citizen_id)


@router.patch("/{obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(obj_id: int, objeto: ZoneReviewUpdate, db: Session = Depends(get_db)):
    updated = zone_review_service.patch(db, obj_id, objeto)
    if not updated:
        raise HTTPException(status_code=404, detail="Review not found")

@router.delete("/{obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(obj_id: int, db: Session = Depends(get_db)):
    deleted = zone_review_service.remove(db, obj_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Review not found")