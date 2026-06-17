from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert
from app.models.prediction_grid_model import PredictionGrid
from app.schemas.prediction_grid_schema import PredictionGridCreate, PredictionGridUpdate
from app.services.time_slot_service import now_in_app_timezone


def create(db: Session, objeto: PredictionGridCreate):
    db_object = PredictionGrid(
        grid_id=objeto.grid_id,
        score_riesgo=objeto.score_riesgo,
        tramo_horario=objeto.tramo_horario,
        nivel_riesgo=objeto.nivel_riesgo,
        fecha_prediccion=objeto.fecha_prediccion or now_in_app_timezone().replace(tzinfo=None),
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(PredictionGrid).all()


def get_by_tramo(db: Session, tramo_horario: str):
    return (
        db.query(PredictionGrid)
        .filter(PredictionGrid.tramo_horario == tramo_horario)
        .all()
    )


def get_by_id(db: Session, object_id: int):
    return db.query(PredictionGrid).filter(PredictionGrid.id == object_id).first()


def upsert_by_grid_and_tramo(
    db: Session,
    *,
    grid_id: int,
    tramo_horario: str,
    score_riesgo: int,
    nivel_riesgo: str,
):
    fecha_prediccion = now_in_app_timezone().replace(tzinfo=None)
    
    statement = (
        insert(PredictionGrid)
        .values(
            grid_id=grid_id,
            tramo_horario=tramo_horario,
            score_riesgo=score_riesgo,
            nivel_riesgo=nivel_riesgo,
            fecha_prediccion = fecha_prediccion
        )
        .on_conflict_do_update(
            index_elements=["grid_id", "tramo_horario"],
            set_={
                "score_riesgo": score_riesgo,
                "nivel_riesgo": nivel_riesgo,
                "fecha_prediccion": fecha_prediccion,
            },
        )
        .returning(PredictionGrid.id)
    )

    prediction_id = db.execute(statement).scalar_one()
    db.commit()
    return get_by_id(db, prediction_id)


def update(db: Session, object_id: int, objeto: PredictionGridUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.score_riesgo = objeto.score_riesgo
        db_object.tramo_horario = objeto.tramo_horario
        db_object.nivel_riesgo = objeto.nivel_riesgo
        db_object.fecha_prediccion = objeto.fecha_prediccion
        db.commit()
        db.refresh(db_object)
    return db_object


def patch(db: Session, object_id: int, objeto: PredictionGridUpdate):
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
