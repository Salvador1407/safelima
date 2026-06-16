from sqlalchemy import Column, Integer, Numeric, String, DateTime, ForeignKey, func, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class PredictionGrid(Base):
    __tablename__ = "predictions_grid"

    id = Column(Integer, primary_key=True, index=True)
    grid_id = Column(Integer, ForeignKey("grids.id", ondelete="CASCADE"), nullable=False)
    score_riesgo = Column(Integer, nullable=True)
    tramo_horario = Column(String(20), nullable=False)
    nivel_riesgo = Column(String(20), nullable=True)
    fecha_prediccion = Column(DateTime, default=datetime.utcnow, server_default=func.now(),)
    
    __table_args__ = (
        CheckConstraint(
            "score_riesgo IN (1, 2, 3)",
            name="ck_predictions_grid_score_riesgo",
        ),
        CheckConstraint(
            "nivel_riesgo IN ('bajo', 'medio', 'alto')",
            name="ck_predictions_grid_nivel_riesgo",
        ),
        UniqueConstraint(
            "grid_id",
            "tramo_horario",
            name="uq_predictions_grid_grid_tramo",
        ),
    )

    # Relaciones
    grid = relationship("Grid", back_populates="predictions")
