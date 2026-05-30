from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class MetricCountOut(BaseModel):
    total: int


class StatusMetricOut(BaseModel):
    estado: str
    total: int


class RiskMetricOut(BaseModel):
    nivel_riesgo: str
    total: int


class ZoneMetricOut(BaseModel):
    grid_id: int
    grid_nombre: str
    total: int

class IncidentTypeMetricOut(BaseModel):
    tipo_incidente: str
    total: int


class DateMetricOut(BaseModel):
    fecha: str
    total: int


class ModelMetricsOut(BaseModel):
    id: int
    nombre_modelo: Optional[str] = None
    version: Optional[str] = None
    precision: Optional[float] = None
    accuracy: Optional[float] = None
    recall: Optional[float] = None
    f1: Optional[float] = None
    auc: Optional[float] = None
    fecha_entrenamiento: Optional[datetime] = None


class AdvancedMetricsOut(BaseModel):
    total_reportes: int
    por_estado: list[StatusMetricOut]
    por_nivel_riesgo: list[RiskMetricOut]
    por_zona: list[ZoneMetricOut]
    por_tipo_incidente: list[IncidentTypeMetricOut]
    por_fecha: list[DateMetricOut]
    modelo: Optional[ModelMetricsOut] = None