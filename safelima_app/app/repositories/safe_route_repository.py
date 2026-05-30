from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.prediction_grid_model import PredictionGrid
from app.models.grid_model import Grid

#Safe Route Repository
def get_predictions_near_point(
    db: Session,
    lat: float,
    lon: float,
    tramo_horario: str | None = None,
    radius_km: float = 0.15,
) -> list[PredictionGrid]:
    """
    Busca predicciones cerca de un punto usando las coordenadas del Grid.
    Si se envía tramo_horario, filtra por ese tramo.
    """

    distance_expr = (
        func.sqrt(
            func.pow(Grid.centro_lat - lat, 2) +
            func.pow(Grid.centro_lon - lon, 2)
        ) * 111.32
    )

    query = (
        db.query(PredictionGrid)
        .join(PredictionGrid.grid)
        .filter(Grid.centro_lat.isnot(None))
        .filter(Grid.centro_lon.isnot(None))
        .filter(distance_expr <= radius_km)
    )

    if tramo_horario:
        query = query.filter(PredictionGrid.tramo_horario == tramo_horario)

    return query.all()