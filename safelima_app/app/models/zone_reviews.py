from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, Text, DateTime
from sqlalchemy.orm import relationship
from app.database.database import Base


class ZoneReview(Base):
    __tablename__ = "zone_reviews"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer,ForeignKey("citizens.id", ondelete="CASCADE"),nullable=False,)
    grid_id = Column(Integer,ForeignKey("grids.id", ondelete="CASCADE"),nullable=False,)
    calificacion = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=False)
    fecha_publicacion = Column(DateTime, default=datetime.utcnow)

    grid = relationship("Grid", back_populates="zonereviews")
    citizen = relationship("Citizen", back_populates="zonereviews")
    likes = relationship("ReviewLike",back_populates="review",cascade="all, delete-orphan",)