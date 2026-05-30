from sqlalchemy import Column, Integer, String, Text, Numeric, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base

class MLModel(Base):
    __tablename__ = "ml_models"

    id = Column(Integer, primary_key=True, index=True)
    nombre_modelo = Column(String(100))
    dataset_id = Column(Integer, ForeignKey("datasets.id", ondelete="SET NULL"))
    version = Column(String(20))
    ruta_modelo = Column(Text)
    precision = Column(Numeric(5, 2))
    accuracy = Column(Numeric(5, 2))
    recall = Column(Numeric(5, 2))
    f1 = Column(Numeric(5, 2))
    auc = Column(Numeric(5, 2))
    fecha_entrenamiento = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    dataset = relationship("Dataset", back_populates="models")
