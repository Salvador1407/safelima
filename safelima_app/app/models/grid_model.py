from sqlalchemy import Column, Integer, String, Numeric, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database.database import Base

class Grid(Base):
    __tablename__ = "grids"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), unique=True, nullable=False)
    grid_lat_idx = Column(Integer)
    grid_lon_idx = Column(Integer)
    centro_lat = Column(Numeric(10, 6))
    centro_lon = Column(Numeric(10, 6))

    __table_args__ = (UniqueConstraint("grid_lat_idx", "grid_lon_idx"),)

    # Relaciones
    favorites = relationship("FavoriteArea", back_populates="grid", cascade="all, delete")
    predictions = relationship("PredictionGrid", back_populates="grid", cascade="all, delete")
    alerts = relationship("UserAlert", back_populates="grid", cascade="all, delete")
    zonereviews = relationship("ZoneReview", back_populates="grid", cascade="all, delete")
