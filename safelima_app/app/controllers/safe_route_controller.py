from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.safe_route_schema import SafeRouteRequest, SafeRouteOut
from app.services import safe_route_service

router = APIRouter(prefix="/routes", tags=["Rutas Seguras"])

#Controller
@router.post("/safe", response_model=SafeRouteOut)
async def get_safe_route(
    payload: SafeRouteRequest,
    db: Session = Depends(get_db),
):
    return await safe_route_service.get_safe_route(db, payload)