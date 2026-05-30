from pydantic import BaseModel
from typing import List


class StatusMetric(BaseModel):
    estado: str
    total: int


class RiskMetric(BaseModel):
    nivel_riesgo: str
    total: int


class ZoneMetric(BaseModel):
    grid_id: int
    grid_nombre: str
    total: int


class DailyMetric(BaseModel):
    fecha: str
    total: int


class UserAlertMetricsOut(BaseModel):
    total_reportes: int
    por_estado: List[StatusMetric]
    por_nivel_riesgo: List[RiskMetric]
    por_zona: List[ZoneMetric]
    por_fecha: List[DailyMetric]