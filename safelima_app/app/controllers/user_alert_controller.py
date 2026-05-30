from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.admin_metrics_schema import AdvancedMetricsOut
from app.schemas.user_alert_schema import UserAlertOut, UserAlertCreate, UserAlertUpdate, UserAlertUpdateAdmin
from app.services import user_alert_service
from app.schemas.user_alert_metrics_schema import UserAlertMetricsOut

router = APIRouter(prefix="/alerts", tags=["Alertas Ciudadanas"])

#@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
#def createAlert(objecto: UserAlertCreate, db: Session = Depends(get_db)):
#    user_alert_service.register(db, objecto)

@router.post("/", status_code=status.HTTP_201_CREATED) # Cambia a 201
def create(
    objecto: UserAlertCreate = Depends(UserAlertCreate.as_form),
    foto: UploadFile | None = File(None),
    db: Session = Depends(get_db)
):
    if foto:
        print(f"DEBUG: El tipo de archivo recibido es: {foto.content_type}")
    try:
        user_alert_service.register(db, objecto, foto)
        return {"message": "Alerta creada correctamente"}
    except ValueError as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/", response_model=list[UserAlertOut])
def get_objects(db: Session = Depends(get_db)):
    return user_alert_service.list_all(db)


@router.get("/{Obj_id}", response_model=UserAlertOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = user_alert_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_200_OK) # Cambiado a 200 para devolver mensaje
def update(
    Obj_id: int, 
    objecto: UserAlertUpdate = Depends(UserAlertUpdate.as_form),
    foto: UploadFile | None = File(None),
    db: Session = Depends(get_db)
):
    return user_alert_service.modify(db, Obj_id, objecto, foto)

@router.patch("/{Obj_id}", status_code=status.HTTP_200_OK)
def patch_alert(Obj_id: int, objecto: UserAlertUpdateAdmin, db: Session = Depends(get_db)):
    try:
        updated = user_alert_service.patch(db, Obj_id, objecto)
        if not updated:
            raise HTTPException(status_code=404, detail="UserAlert not found")

        return {
            "message": "Estado de alerta actualizado correctamente",
            "alert_id": updated.id,
            "nuevo_estado": updated.estado
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return user_alert_service.remove(db, Obj_id)

#Funcionalidades
@router.get("/citizen/{citizen_id}", response_model=list[UserAlertOut])
def get_alerts_by_citizen(citizen_id: int, db: Session = Depends(get_db)):
    return user_alert_service.list_by_citizen(db, citizen_id)

@router.get("/metrics/summary", response_model=UserAlertMetricsOut)
def get_alert_metrics(db: Session = Depends(get_db)):
    return user_alert_service.get_metrics(db)

@router.get("/metrics/advanced", response_model=AdvancedMetricsOut)
def get_advanced_metrics(db: Session = Depends(get_db)):
    return user_alert_service.get_advanced_metrics(db)