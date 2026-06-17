from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ml_prediction_schema import MLBatchRunOut, MLModelStatusOut
from app.security.auth import require_admin
from app.services import ml_batch_service, ml_model_loader_service
from app.services.ml_model_loader_service import MLModelLoadError


router = APIRouter(prefix="/admin/ml", tags=["Admin ML"])


@router.post("/batch-predictions", response_model=MLBatchRunOut)
def run_batch_predictions(
    _: dict = Depends(require_admin),
    db: Session = Depends(get_db),
):
    try:
        return ml_batch_service.run_batch_predictions(db)
    except MLModelLoadError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.get("/models/status", response_model=MLModelStatusOut)
def get_models_status(_: dict = Depends(require_admin)):
    return ml_model_loader_service.get_status()

