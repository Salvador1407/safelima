from sqlalchemy.orm import Session
from app.models.prediction_grid_model import PredictionGrid
from app.schemas.prediction_grid_schema import PredictionGridCreate, PredictionGridUpdate

def create(db: Session, objeto: PredictionGridCreate):
    db_object = PredictionGrid(
        grid_id=objeto.grid_id,
        score_riesgo=objeto.score_riesgo,
        tramo_horario=objeto.tramo_horario,
        nivel_riesgo=objeto.nivel_riesgo,
        fecha_prediccion=objeto.fecha_prediccion,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(PredictionGrid).all()


def get_by_id(db: Session, object_id: int):
    return db.query(PredictionGrid).filter(PredictionGrid.id == object_id).first()


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