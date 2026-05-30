from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from app.models.zone_reviews import ZoneReview
from app.schemas.zone_review_schema import ZoneReviewCreate, ZoneReviewUpdate


def create(db: Session, objeto: ZoneReviewCreate):
    db_object = ZoneReview(**objeto.dict())
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return (
        db.query(ZoneReview)
        .options(
            joinedload(ZoneReview.citizen),
            joinedload(ZoneReview.grid),
            joinedload(ZoneReview.likes),
        )
        .filter(ZoneReview.id == db_object.id)
        .first()
    )


def get(db: Session):
    return (
        db.query(ZoneReview)
        .options(
            joinedload(ZoneReview.citizen),
            joinedload(ZoneReview.grid),
            joinedload(ZoneReview.likes),
        )
        .order_by(ZoneReview.fecha_publicacion.desc())
        .all()
    )


def get_by_id(db: Session, object_id: int):
    return (
        db.query(ZoneReview)
        .options(
            joinedload(ZoneReview.citizen),
            joinedload(ZoneReview.grid),
            joinedload(ZoneReview.likes),
        )
        .filter(ZoneReview.id == object_id)
        .first()
    )


def get_by_grid_id(db: Session, grid_id: int):
    return (
        db.query(ZoneReview)
        .options(
            joinedload(ZoneReview.citizen),
            joinedload(ZoneReview.grid),
            joinedload(ZoneReview.likes),
        )
        .filter(ZoneReview.grid_id == grid_id)
        .order_by(ZoneReview.fecha_publicacion.desc())
        .all()
    )


def get_summary_by_grid_id(db: Session, grid_id: int):
    total_reviews = (
        db.query(func.count(ZoneReview.id))
        .filter(ZoneReview.grid_id == grid_id)
        .scalar()
    ) or 0

    promedio = (
        db.query(func.avg(ZoneReview.calificacion))
        .filter(ZoneReview.grid_id == grid_id)
        .scalar()
    ) or 0

    reviews = get_by_grid_id(db, grid_id)

    return {
        "grid_id": grid_id,
        "total_reviews": total_reviews,
        "promedio_calificacion": round(float(promedio), 1),
        "reviews": reviews,
    }


def patch(db: Session, object_id: int, objeto: ZoneReviewUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_object, key, value)

    db.commit()
    db.refresh(db_object)
    return db_object


def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object