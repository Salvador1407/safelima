from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class Dataset(Base):
    __tablename__ = "datasets"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100))
    fuente = Column(String(100))
    ruta_archivo = Column(Text)
    num_registros = Column(Integer)
    descripcion = Column(Text)
    fecha_ingreso = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    models = relationship("MLModel", back_populates="dataset")
