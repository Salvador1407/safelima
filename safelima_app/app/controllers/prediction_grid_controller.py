from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.prediction_grid_schema import PredictionGridOut, PredictionGridCreate, PredictionGridUpdate
from app.services import prediction_grid_service

router = APIRouter(prefix="/predictions", tags=["Predicciones"])


@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: PredictionGridCreate, db: Session = Depends(get_db)):
    prediction_grid_service.register(db, objecto)


@router.get("/", response_model=list[PredictionGridOut])
def get_objects(db: Session = Depends(get_db)):
    return prediction_grid_service.list_all(db)


@router.get("/{Obj_id}", response_model=PredictionGridOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = prediction_grid_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto


@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: PredictionGridUpdate, db: Session = Depends(get_db)):
    prediction_grid_service.modify(db, Obj_id, objecto)

@router.patch("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: PredictionGridUpdate, db: Session = Depends(get_db)):
    updated = prediction_grid_service.patch(db, Obj_id, objecto)
    if not updated:
        raise HTTPException(status_code=404, detail="PredictionGrid not found")

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return prediction_grid_service.remove(db, Obj_id)
