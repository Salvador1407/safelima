import logging

from sqlalchemy.orm import Session
from app.repositories import grid_repository, user_alert_repository
from app.schemas.user_alert_schema import UserAlertCreate, UserAlertUpdate, UserAlertUpdateAdmin
from fastapi import UploadFile
from app.services import ml_inference_service, prediction_grid_service
from app.services.gcs_service import upload_alert_image
from app.services.time_slot_service import get_time_slot
from app.services.time_slot_service import now_in_app_timezone


logger = logging.getLogger(__name__)
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}

def registerAlert(db: Session, objecto: UserAlertCreate):
    created_alert = user_alert_repository.create(db, objecto)
    _recalculate_prediction_for_alert(db, created_alert)
    return created_alert


def _recalculate_prediction_for_alert(db: Session, alert) -> None:
    try:
        grid = grid_repository.get_by_id(db, alert.grid_id)
        if not grid:
            raise ValueError(f"Grid no encontrado: {alert.grid_id}")

        alert_datetime = alert.fecha or now_in_app_timezone().replace(tzinfo=None)
        tramo_horario = get_time_slot(alert_datetime)
        prediction = ml_inference_service.predict_online(
            fecha=alert_datetime,
            hora=alert_datetime.time(),
            lugar=grid.nombre,
            tramo=tramo_horario,
            tipo_incidente=alert.tipo_incidente,
        )
        user_alert_repository.update_risk(
            db=db,
            alert_id=alert.id,
            nivel_riesgo=prediction["nivel_riesgo"],
        )
        prediction_grid_service.upsert_prediction(
            db=db,
            grid_id=alert.grid_id,
            tramo_horario=tramo_horario,
            score_riesgo=prediction["score_riesgo"],
            nivel_riesgo=prediction["nivel_riesgo"],
        )
    except Exception as exc:
        db.rollback()
        logger.exception(
            "No se pudo recalcular predicción online para alerta %s: %s",
            getattr(alert, "id", None),
            exc,
        )

def register(db: Session, objecto: UserAlertCreate, foto: UploadFile | None = None):
    image_url = None
    if foto and foto.filename: # Validar que realmente hay un archivo
        if foto.content_type not in ALLOWED_IMAGE_TYPES:
            raise ValueError("Formato de imagen no permitido")
        
        try:
            image_url = upload_alert_image(foto, objecto.citizen_id)
        except Exception as e:
            # Si falla la subida a la nube, lanzamos error antes de tocar la BD
            raise ValueError(f"Error al subir la imagen a la nube: {str(e)}")

    # Asignamos la URL resultante al campo correspondiente
    objecto.ruta_foto = image_url
    
    created_alert = user_alert_repository.create(db, objecto)
    _recalculate_prediction_for_alert(db, created_alert)
    return created_alert

def list_all(db: Session):
    return user_alert_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return user_alert_repository.get_by_id(db, object_id)

def modify(db: Session, object_id: int, objecto: UserAlertUpdate, foto: UploadFile | None = None):
    # 1. Buscar la alerta actual para saber quién es el ciudadano
    db_alert = user_alert_repository.get_by_id(db, object_id)
    if not db_alert:
        raise ValueError("Alerta no encontrada")

    # 2. Si hay foto nueva, subirla
    if foto and foto.filename:
        # Reutilizamos tu función de gcs_service
        url = upload_alert_image(foto, db_alert.citizen_id)
        objecto.ruta_foto = url

    return user_alert_repository.update(db, object_id, objecto)


ALLOWED_STATUS = ["Recibido", "En proceso", "Cerrado"]
def patch(db: Session, object_id: int, objecto: UserAlertUpdateAdmin):
    if objecto.estado is not None and objecto.estado not in ALLOWED_STATUS:
        raise ValueError("Estado no válido. Use: Recibido, En proceso o Cerrado")
    return user_alert_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return user_alert_repository.delete(db, object_id)

#Funcionalidades
def list_by_citizen(db: Session, citizen_id: int):
    return user_alert_repository.get_by_citizen(db, citizen_id)

def get_metrics(db: Session):
    return {
        "total_reportes": user_alert_repository.get_total_alerts(db),
        "por_estado": user_alert_repository.get_alerts_by_status(db),
        "por_nivel_riesgo": user_alert_repository.get_alerts_by_risk(db),
        "por_zona": user_alert_repository.get_alerts_by_zone(db),
        "por_fecha": user_alert_repository.get_alerts_by_date(db),
    }
    
def get_advanced_metrics(db: Session):
    return {
        "total_reportes": user_alert_repository.get_total_alerts(db),
        "por_estado": user_alert_repository.get_alerts_by_status(db),
        "por_nivel_riesgo": user_alert_repository.get_alerts_by_risk(db),
        "por_zona": user_alert_repository.get_alerts_by_zone(db),
        "por_tipo_incidente": user_alert_repository.get_alerts_by_incident_type(db),
        "por_fecha": user_alert_repository.get_alerts_by_date(db),
        "modelo": user_alert_repository.get_latest_model_metrics(db),
    }
