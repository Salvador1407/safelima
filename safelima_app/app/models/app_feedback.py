from sqlalchemy import Column, Integer, String, Text, Numeric, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class AppFeedback(Base):
    __tablename__ = "app_feedback"
    
    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer, ForeignKey("citizens.id", ondelete="CASCADE"), nullable=False, index=True, unique=True)
    estrellas = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=True)
    fecha = Column(DateTime, default=datetime.utcnow)

    # Relación
    citizen = relationship("Citizen")