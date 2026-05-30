from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database.database import Base


class ReviewLike(Base):
    __tablename__ = "review_likes"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer,ForeignKey("citizens.id", ondelete="CASCADE"),nullable=False,)
    review_id = Column(Integer,ForeignKey("zone_reviews.id", ondelete="CASCADE"),nullable=False,)
    
    # Relaciones
    review = relationship("ZoneReview", back_populates="likes")
    citizen = relationship("Citizen")

    __table_args__ = (UniqueConstraint("citizen_id", "review_id", name="_citizen_review_uc"),)