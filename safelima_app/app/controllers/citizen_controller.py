from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.citizen_schema import CitizenOut, CitizenCreate, CitizenUpdate,CitizenGet
from app.services import citizen_service

router = APIRouter(prefix="/citizens", tags=["Ciudadanos"])

@router.post("/", response_model=CitizenOut, status_code=status.HTTP_201_CREATED)
def create(objecto: CitizenCreate, db: Session = Depends(get_db)):
    return citizen_service.register(db, objecto)

@router.get("/", response_model=list[CitizenOut])
def get_objects(db: Session = Depends(get_db)):
    return citizen_service.list_all(db)

@router.get("/{Obj_id}", response_model=CitizenGet)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = citizen_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: CitizenUpdate, db: Session = Depends(get_db)):
    citizen_service.modify(db, Obj_id, objecto)
    
@router.patch("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: CitizenUpdate, db: Session = Depends(get_db)):
    updated = citizen_service.patch(db, Obj_id, objecto)
    if not updated:
        raise HTTPException(status_code=404, detail="Citizen not found")

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return citizen_service.remove(db, Obj_id)
