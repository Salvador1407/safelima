from datetime import datetime
from zoneinfo import ZoneInfo

from app.core.config import settings


TIME_SLOTS = ("Mañana", "Tarde", "Noche")


def get_app_timezone() -> ZoneInfo:
    return ZoneInfo(getattr(settings, "TZ", "America/Lima"))


def now_in_app_timezone() -> datetime:
    return datetime.now(get_app_timezone())


def to_app_timezone(value: datetime | None = None) -> datetime:
    tz = get_app_timezone()
    if value is None:
        return datetime.now(tz)
    if value.tzinfo is None:
        return value.replace(tzinfo=tz)
    return value.astimezone(tz)


def validate_time_slot(tramo_horario: str) -> str:
    normalized = (tramo_horario or "").strip()
    if normalized not in TIME_SLOTS:
        raise ValueError("tramo_horario debe ser Mañana, Tarde o Noche")
    return normalized


def get_time_slot(value: datetime | None = None) -> str:
    hour = to_app_timezone(value).hour

    if 6 <= hour < 12:
        return "Mañana"
    if 12 <= hour < 18:
        return "Tarde"
    return "Noche"

