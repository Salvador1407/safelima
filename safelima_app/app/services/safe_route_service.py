from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.schemas.safe_route_schema import (
    SafeRouteRequest,
    SafeRouteOut,
    SafeRouteOptionOut,
    RoutePointOut,
)
from app.services.ors_route_provider_service import get_alternative_routes
from app.services.route_risk_evaluator_service import evaluate_route_risk

#Service Route 
async def get_safe_route(
    db: Session,
    payload: SafeRouteRequest,
) -> SafeRouteOut:
    # 1. Llamada al proveedor de rutas (ORS)
    # Asegúrate de que get_alternative_routes use el endpoint /geojson
    ors_data = await get_alternative_routes(
        origin_lat=payload.origin_lat,
        origin_lon=payload.origin_lon,
        destination_lat=payload.destination_lat,
        destination_lon=payload.destination_lon,
    )

    alternatives: list[SafeRouteOptionOut] = []

    # 2. Procesamiento de Features (Formato GeoJSON)
    # ORS en modo geojson devuelve una lista de 'features'
    features = ors_data.get("features", [])
    
    if not features:
        raise HTTPException(
            status_code=502, 
            detail="No se encontraron rutas disponibles en el proveedor."
        )

    for idx, feature in enumerate(features):
        # La geometría contiene el tipo (LineString) y las coordenadas
        geometry = feature.get("geometry", {})
        coordinates = geometry.get("coordinates", []) # Lista de [lon, lat]
        
        # Las propiedades contienen el resumen de distancia y duración
        properties = feature.get("properties", {})
        summary = properties.get("summary", {})

        # 3. Evaluación de Riesgo mediante el Repositorio
        # Enviamos las coordenadas para cruzar con predictions_grid
        risk_data = evaluate_route_risk(db, coordinates)

        # 4. Construcción de la Polilínea para el Frontend (Flutter)
        # Convertimos de [lon, lat] (ORS) a objetos {lat, lon} (Pydantic Out)
        polyline = [
            RoutePointOut(lat=lat, lon=lon)
            for lon, lat in coordinates
        ]

        alternatives.append(
            SafeRouteOptionOut(
                route_index=idx,
                distance_meters=float(summary.get("distance", 0.0)),
                duration_seconds=float(summary.get("duration", 0.0)),
                risk_score=float(risk_data["risk_score"]),
                danger_zones_crossed=int(risk_data["danger_zones_crossed"]),
                medium_zones_crossed=int(risk_data["medium_zones_crossed"]),
                low_zones_crossed=int(risk_data["low_zones_crossed"]),
                tramo_horario_evaluado=risk_data.get("tramo_horario_evaluado"),
                polyline=polyline,
            )
        )

    # 5. Algoritmo de Selección de la Mejor Ruta
    # Prioridad 1: Menor Risk Score (Seguridad primero)
    # Prioridad 2: Menor Duración (Eficiencia si el riesgo es igual)
    alternatives.sort(key=lambda r: (r.risk_score, r.duration_seconds))

    best_route = alternatives[0]

    return SafeRouteOut(
        best_route_index=best_route.route_index,
        best_route=best_route,
        alternatives=alternatives,
    )