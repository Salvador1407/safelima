from pydantic import BaseModel


class ReviewLikeCreate(BaseModel):
    citizen_id: int
    review_id: int


class ReviewLikeOut(BaseModel):
    id: int
    citizen_id: int
    review_id: int

    class Config:
        from_attributes = True


class ReviewLikeToggleResponse(BaseModel):
    liked: bool
    likes_count: int
    review_id: int