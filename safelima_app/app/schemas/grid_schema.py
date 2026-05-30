from pydantic import BaseModel
from typing import Optional

class GridBase(BaseModel):
    nombre: Optional[str] = None
    grid_lat_idx: Optional[int] = None
    grid_lon_idx: Optional[int] = None
    centro_lat: Optional[float] = None
    centro_lon: Optional[float] = None


class GridCreate(GridBase):
    pass


class GridUpdate(GridBase):
    pass


class GridGet(GridBase):
    id: int


class GridOut(GridBase):
    id: int
    class Config:
        from_attributes = True
