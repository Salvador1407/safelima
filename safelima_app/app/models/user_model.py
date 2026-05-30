from sqlalchemy import Column, Integer, String, Float,Text, ForeignKey, Boolean, Date, DateTime
from sqlalchemy.orm import relationship
from app.database.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    password = Column(Text, nullable=False) 
    enable = Column(Boolean, default=True)
    role = Column(String(20), nullable=False)

    citizen = relationship("Citizen", back_populates="user")


