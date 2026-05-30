from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database.database import Base
from datetime import datetime

class FavoriteArea(Base):
    __tablename__ = "favorite_areas"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer, ForeignKey("citizens.id", ondelete="CASCADE"), nullable=False)
    grid_id = Column(Integer, ForeignKey("grids.id", ondelete="CASCADE"), nullable=False)
    fecha_agregado = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (UniqueConstraint("citizen_id", "grid_id"),)

    # Relaciones
    citizen = relationship("Citizen", back_populates="favorites")
    grid = relationship("Grid", back_populates="favorites")
