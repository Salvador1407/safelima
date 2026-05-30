from pydantic import BaseModel
from typing import Optional


class ServiceStatusOut(BaseModel):
    name: str
    status: str
    detail: Optional[str] = None


class ErrorLogOut(BaseModel):
    timestamp: str
    severity: str
    message: str


class TechnicalDashboardOut(BaseModel):
    cloud_run: ServiceStatusOut
    cloud_sql: ServiceStatusOut
    recent_errors: list[ErrorLogOut]
    checked_at: str