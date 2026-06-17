from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from zoneinfo import ZoneInfo
from app.database.database import Base

def lima_now_naive():
    return datetime.now(ZoneInfo("America/Lima")).replace(tzinfo=None)

class UserAlert(Base):
    __tablename__ = "user_alerts"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer, ForeignKey("citizens.id", ondelete="CASCADE"), nullable=False)
    grid_id = Column(Integer, ForeignKey("grids.id", ondelete="CASCADE"), nullable=False)
    titulo = Column(String(100))
    tipo_incidente = Column(String(50), nullable=False)
    descripcion = Column(Text)
    nivel_riesgo = Column(String(20))
    ruta_foto = Column(Text)
    estado = Column(String(20), nullable=False, default="Recibido")
    fecha = Column(DateTime, default=lima_now_naive)

    # Relaciones
    citizen = relationship("Citizen", back_populates="alerts")
    grid = relationship("Grid", back_populates="alerts")
