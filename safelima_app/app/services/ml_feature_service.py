from datetime import date, datetime, time

from app.services.time_slot_service import validate_time_slot


BATCH_FEATURES = [
    "anio",
    "mes",
    "dia",
    "dia_semana",
    "tramo_horario",
    "lugar_especifico",
]

ONLINE_FEATURES = [
    "anio",
    "mes",
    "dia",
    "dia_semana",
    "hora_decimal",
    "tramo_horario",
    "lugar_especifico",
    "tipo_incidente",
]

INCIDENT_LABELS = (
    "Acoso callejero",
    "Vandalismo",
    "Hurto de celular",
    "Robo al paso",
    "Asalto con arma blanca",
    "Asalto con arma de fuego",
    "Robo de vehículo",
    "Pelea en la vía pública",
    "Microcomercialización de droga",
    "Riña entre grupos",
)

INCIDENT_CODE_TO_LABEL = {
    "acoso": "Acoso callejero",
    "vandalismo": "Vandalismo",
    "hurto": "Hurto de celular",
    "robo": "Robo al paso",
    "asalto": "Asalto con arma blanca",
    "robo_vehiculo": "Robo de vehículo",
    "pelea": "Pelea en la vía pública",
    "droga": "Microcomercialización de droga",
    "rina": "Riña entre grupos",
}


def _strip_spaces(value: str) -> str:
    return " ".join(value.strip().split())


def _maybe_fix_mojibake(value: str) -> str:
    try:
        return value.encode("latin1").decode("utf-8")
    except UnicodeError:
        return value


def _incident_lookup() -> dict[str, str]:
    lookup = {label.lower(): label for label in INCIDENT_LABELS}
    lookup.update({code.lower(): label for code, label in INCIDENT_CODE_TO_LABEL.items()})
    return lookup


def normalize_incident_type(tipo_incidente: str) -> str:
    raw_value = _strip_spaces(tipo_incidente or "")
    if not raw_value:
        raise ValueError("tipo_incidente es requerido")

    lookup = _incident_lookup()
    candidates = [raw_value, _maybe_fix_mojibake(raw_value)]

    for candidate in candidates:
        normalized_key = _strip_spaces(candidate).lower()
        if normalized_key in lookup:
            return lookup[normalized_key]

    raise ValueError(f"tipo_incidente no reconocido: {tipo_incidente}")


def _coerce_datetime(fecha: datetime | date | str, hora: time | str | None = None) -> datetime:
    if isinstance(fecha, datetime):
        base = fecha
    elif isinstance(fecha, date):
        base = datetime.combine(fecha, time.min)
    elif isinstance(fecha, str):
        base = datetime.fromisoformat(fecha)
    else:
        raise ValueError("fecha debe ser date, datetime o string ISO")

    if hora is None:
        return base

    if isinstance(hora, time):
        parsed_time = hora
    elif isinstance(hora, str):
        parsed_time = time.fromisoformat(hora)
    else:
        raise ValueError("hora debe ser time o string ISO")

    return datetime.combine(base.date(), parsed_time)


def _validate_place(lugar: str) -> str:
    normalized = _strip_spaces(lugar or "")
    if not normalized:
        raise ValueError("lugar_especifico es requerido")
    return normalized


def build_batch_feature_row(
    fecha: datetime | date | str,
    lugar: str,
    tramo: str,
) -> dict:
    dt = _coerce_datetime(fecha)
    return {
        "anio": dt.year,
        "mes": dt.month,
        "dia": dt.day,
        "dia_semana": dt.weekday(),
        "tramo_horario": validate_time_slot(tramo),
        "lugar_especifico": _validate_place(lugar),
    }


def build_online_feature_row(
    fecha: datetime | date | str,
    hora: time | str | None,
    lugar: str,
    tramo: str,
    tipo_incidente: str,
) -> dict:
    dt = _coerce_datetime(fecha, hora)
    hora_decimal = dt.hour + dt.minute / 60 + dt.second / 3600

    return {
        "anio": dt.year,
        "mes": dt.month,
        "dia": dt.day,
        "dia_semana": dt.weekday(),
        "hora_decimal": hora_decimal,
        "tramo_horario": validate_time_slot(tramo),
        "lugar_especifico": _validate_place(lugar),
        "tipo_incidente": normalize_incident_type(tipo_incidente),
    }

