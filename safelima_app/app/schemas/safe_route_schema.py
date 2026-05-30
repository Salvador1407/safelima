from pydantic import BaseModel, Field
from typing import List

#SafeRoute Schemas
class SafeRouteRequest(BaseModel):
    origin_lat: float = Field(..., ge=-90, le=90)
    origin_lon: float = Field(..., ge=-180, le=180)
    destination_lat: float = Field(..., ge=-90, le=90)
    destination_lon: float = Field(..., ge=-180, le=180)


class RoutePointOut(BaseModel):
    lat: float
    lon: float


class SafeRouteOptionOut(BaseModel):
    route_index: int
    distance_meters: float
    duration_seconds: float
    risk_score: float
    danger_zones_crossed: int
    medium_zones_crossed: int
    low_zones_crossed: int
    tramo_horario_evaluado: str | None = None
    polyline: List[RoutePointOut]


class SafeRouteOut(BaseModel):
    best_route_index: int
    best_route: SafeRouteOptionOut
    alternatives: List[SafeRouteOptionOut]