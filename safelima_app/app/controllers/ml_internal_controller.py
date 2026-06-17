from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ml_prediction_schema import MLBatchRunOut
from app.security.scheduler_auth import require_scheduler_token
from app.services import ml_batch_service
from app.services.ml_model_loader_service import MLModelLoadError


router = APIRouter(prefix="/internal/ml", tags=["Internal ML"])


@router.post(
    "/batch-predictions",
    response_model=MLBatchRunOut,
    include_in_schema=False,
)
def run_scheduler_batch_predictions(
    _: None = Depends(require_scheduler_token),
    db: Session = Depends(get_db),
):
    try:
        return ml_batch_service.run_batch_predictions(db)
    except MLModelLoadError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
