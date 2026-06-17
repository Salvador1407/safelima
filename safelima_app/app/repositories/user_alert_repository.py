from sqlalchemy.orm import Session
from app.models.ml_model import MLModel
from app.models.user_alert_model import UserAlert
from app.schemas.user_alert_schema import UserAlertCreate, UserAlertUpdate
from sqlalchemy import func
from app.models.grid_model import Grid
from app.services.time_slot_service import now_in_app_timezone

def create(db: Session, objeto: UserAlertCreate):
    db_object = UserAlert(
        citizen_id=objeto.citizen_id,
        grid_id=objeto.grid_id,
        titulo=objeto.titulo,
        tipo_incidente=objeto.tipo_incidente,
        descripcion=objeto.descripcion,
        nivel_riesgo=None,
        ruta_foto=objeto.ruta_foto,
        estado = "Recibido",
        fecha=now_in_app_timezone().replace(tzinfo=None),
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return (
        db.query(UserAlert)
        .order_by(UserAlert.fecha.desc())
        .all()
    )

def get_by_id(db: Session, object_id: int):
    return db.query(UserAlert).filter(UserAlert.id == object_id).first()

def update(db: Session, object_id: int, objeto: UserAlertUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.titulo = objeto.titulo
        db_object.tipo_incidente = objeto.tipo_incidente
        db_object.descripcion = objeto.descripcion
        db_object.nivel_riesgo = objeto.nivel_riesgo
        
        if objeto.ruta_foto:
            db_object.ruta_foto = objeto.ruta_foto
            
        db.commit()
        db.refresh(db_object)
    return db_object

def patch(db: Session, object_id: int, objeto: UserAlertUpdate):
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

#Funcionalidades
def get_by_citizen(db: Session, citizen_id: int):
    return (
        db.query(UserAlert)
        .filter(UserAlert.citizen_id == citizen_id)
        .order_by(UserAlert.fecha.desc())
        .all()
    )
    


def get_total_alerts(db: Session):
    return db.query(func.count(UserAlert.id)).scalar() or 0


def get_alerts_by_status(db: Session):
    rows = (
        db.query(
            UserAlert.estado,
            func.count(UserAlert.id).label("total")
        )
        .group_by(UserAlert.estado)
        .all()
    )

    return [{"estado": row[0], "total": row[1]} for row in rows]


def get_alerts_by_risk(db: Session):
    rows = (
        db.query(
            UserAlert.nivel_riesgo,
            func.count(UserAlert.id).label("total")
        )
        .group_by(UserAlert.nivel_riesgo)
        .all()
    )

    return [{"nivel_riesgo": row[0], "total": row[1]} for row in rows]


def get_alerts_by_zone(db: Session):
    rows = (
        db.query(
            UserAlert.grid_id,
            Grid.nombre,
            func.count(UserAlert.id).label("total")
        )
        .join(Grid, Grid.id == UserAlert.grid_id)
        .group_by(UserAlert.grid_id, Grid.nombre)
        .order_by(func.count(UserAlert.id).desc())
        .all()
    )

    return [
        {
            "grid_id": row[0],
            "grid_nombre": row[1],
            "total": row[2],
        }
        for row in rows
    ]


def get_alerts_by_date(db: Session):
    rows = (
        db.query(
            func.date(UserAlert.fecha).label("fecha"),
            func.count(UserAlert.id).label("total")
        )
        .group_by(func.date(UserAlert.fecha))
        .order_by(func.date(UserAlert.fecha))
        .all()
    )

    return [
        {
            "fecha": str(row[0]),
            "total": row[1],
        }
        for row in rows
    ]
    
def get_alerts_by_incident_type(db: Session):
    rows = (
        db.query(
            UserAlert.tipo_incidente,
            func.count(UserAlert.id).label("total")
        )
        .group_by(UserAlert.tipo_incidente)
        .order_by(func.count(UserAlert.id).desc())
        .all()
    )

    return [
        {
            "tipo_incidente": row[0],
            "total": row[1],
        }
        for row in rows
    ]
    
def get_latest_model_metrics(db: Session):
    model = (
        db.query(MLModel)
        .order_by(MLModel.fecha_entrenamiento.desc())
        .first()
    )

    if not model:
        return None

    return {
        "id": model.id,
        "nombre_modelo": model.nombre_modelo,
        "version": model.version,
        "precision": float(model.precision) if model.precision is not None else None,
        "accuracy": float(model.accuracy) if model.accuracy is not None else None,
        "recall": float(model.recall) if model.recall is not None else None,
        "f1": float(model.f1) if model.f1 is not None else None,
        "auc": float(model.auc) if model.auc is not None else None,
        "fecha_entrenamiento": model.fecha_entrenamiento,
    }
    
def update_risk(db: Session, alert_id: int, nivel_riesgo: str):
    alert = db.query(UserAlert).filter(UserAlert.id == alert_id).first()
    if not alert:
        return None

    alert.nivel_riesgo = nivel_riesgo
    db.commit()
    db.refresh(alert)
    return alert