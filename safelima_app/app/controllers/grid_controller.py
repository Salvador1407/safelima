from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.grid_schema import GridOut, GridCreate, GridUpdate
from app.services import grid_service

router = APIRouter(prefix="/grids", tags=["Zonas (Grids)"])

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: GridCreate, db: Session = Depends(get_db)):
    grid_service.register(db, objecto)


@router.get("/", response_model=list[GridOut])
def get_objects(db: Session = Depends(get_db)):
    return grid_service.list_all(db)


@router.get("/{Obj_id}", response_model=GridOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = grid_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto


@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: GridUpdate, db: Session = Depends(get_db)):
    grid_service.modify(db, Obj_id, objecto)

@router.patch("/{Obj_id}",status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: GridUpdate, db: Session = Depends(get_db)):
    updated = grid_service.patch(db, Obj_id, objecto)
    if not updated:
        raise HTTPException(status_code=404, detail="Grid not found")

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return grid_service.remove(db, Obj_id)
