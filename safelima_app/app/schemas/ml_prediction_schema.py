from datetime import datetime

from pydantic import BaseModel


class MLBatchRunOut(BaseModel):
    grids_processed: int
    predictions_updated: int
    errors: list[str]
    ran_at: datetime
    tramo_horarios: list[str]


class MLModelStatusOut(BaseModel):
    source: str
    loaded: bool
    batch_loaded: bool
    online_loaded: bool
    errors: dict[str, str]
    gcs_bucket: str
    batch_model_blob: str
    online_model_blob: str
    local_dir: str
    batch_model_path: str
    online_model_path: str
