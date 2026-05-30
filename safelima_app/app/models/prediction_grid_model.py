from sqlalchemy import Column, Integer, Numeric, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class PredictionGrid(Base):
    __tablename__ = "predictions_grid"

    id = Column(Integer, primary_key=True, index=True)
    grid_id = Column(Integer, ForeignKey("grids.id", ondelete="CASCADE"), nullable=False)
    score_riesgo = Column(Integer)
    tramo_horario = Column(String(20))
    nivel_riesgo = Column(String(20))
    fecha_prediccion = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    grid = relationship("Grid", back_populates="predictions")
