from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database.database import Base

class Citizen(Base):
    __tablename__ = "citizens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    full_name = Column(String(100))
    correo = Column(String(120))

    # Relaciones
    user = relationship("User", back_populates="citizen")
    favorites = relationship("FavoriteArea", back_populates="citizen", cascade="all, delete")
    alerts = relationship("UserAlert", back_populates="citizen", cascade="all, delete")
    zonereviews = relationship("ZoneReview", back_populates="citizen", cascade="all, delete")
