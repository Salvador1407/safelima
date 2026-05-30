from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.dataset_schema import DatasetOut, DatasetCreate, DatasetUpdate
from app.services import dataset_service

router = APIRouter(prefix="/datasets", tags=["Datasets ML"])


@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: DatasetCreate, db: Session = Depends(get_db)):
    dataset_service.register(db, objecto)


@router.get("/", response_model=list[DatasetOut])
def get_objects(db: Session = Depends(get_db)):
    return dataset_service.list_all(db)


@router.get("/{Obj_id}", response_model=DatasetOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = dataset_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto


@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: DatasetUpdate, db: Session = Depends(get_db)):
    dataset_service.modify(db, Obj_id, objecto)
    
@router.patch("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: DatasetUpdate, db: Session = Depends(get_db)):
    updated = dataset_service.patch(db, Obj_id, objecto)
    if not updated:
        raise HTTPException(status_code=404, detail="Dataset not found")

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return dataset_service.remove(db, Obj_id)
