from sqlalchemy.orm import Session
from app.models.ml_model import MLModel
from app.schemas.ml_model_schema import MLModelCreate, MLModelUpdate


def create(db: Session, objeto: MLModelCreate):
    db_object = MLModel(
        nombre_modelo=objeto.nombre_modelo,
        dataset_id=objeto.dataset_id,
        version=objeto.version,
        ruta_modelo=objeto.ruta_modelo,
        precision=objeto.precision,
        accuracy=objeto.accuracy,
        recall=objeto.recall,
        f1=objeto.f1,
        auc=objeto.auc,
        fecha_entrenamiento=objeto.fecha_entrenamiento,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return db.query(MLModel).all()


def get_by_id(db: Session, object_id: int):
    return db.query(MLModel).filter(MLModel.id == object_id).first()


def update(db: Session, object_id: int, objeto: MLModelUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.nombre_modelo = objeto.nombre_modelo
        db_object.version = objeto.version
        db_object.ruta_modelo = objeto.ruta_modelo
        db_object.precision = objeto.precision
        db_object.accuracy = objeto.accuracy
        db_object.recall = objeto.recall
        db_object.f1 = objeto.f1
        db_object.auc = objeto.auc
        db_object.fecha_entrenamiento = objeto.fecha_entrenamiento
        db.commit()
        db.refresh(db_object)
    return db_object

def patch(db: Session, object_id: int, objeto: MLModelUpdate):
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
