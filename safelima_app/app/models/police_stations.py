from sqlalchemy import Column, Integer, String, Text, Numeric, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class PoliceStation(Base):
    __tablename__ = "police_stations"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    direccion = Column(Text)
    telefono = Column(String(20))
    latitud = Column(Numeric(10, 6), nullable=False)
    longitud = Column(Numeric(10, 6), nullable=False)
    distrito = Column(String(50))
    fecha_registro = Column(DateTime, default=datetime.utcnow)