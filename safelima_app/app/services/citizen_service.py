from sqlalchemy.orm import Session
from app.repositories import citizen_repository
from app.schemas.citizen_schema import CitizenCreate, CitizenUpdate


def register(db: Session, objecto: CitizenCreate):
    return citizen_repository.create(db, objecto)


def list_all(db: Session):
    return citizen_repository.get(db)


def find_by_id(db: Session, object_id: int):
    return citizen_repository.get_by_id(db, object_id)


def modify(db: Session, object_id: int, objecto: CitizenUpdate):
    return citizen_repository.update(db, object_id, objecto)

def patch(db: Session, object_id: int, objecto: CitizenUpdate):
    return citizen_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return citizen_repository.delete(db, object_id)

#Funcionalidades
def getUsersDetail(db: Session, object_id: int):
    return citizen_repository.getUsersDetail(db,object_id)