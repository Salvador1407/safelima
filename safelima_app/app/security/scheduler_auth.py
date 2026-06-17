import secrets

from fastapi import Header, HTTPException, status

from app.core.config import settings


def require_scheduler_token(
    x_scheduler_token: str | None = Header(default=None, alias="X-Scheduler-Token"),
) -> None:
    expected_token = settings.SCHEDULER_TOKEN

    if not expected_token:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Token de scheduler no configurado",
        )

    if not x_scheduler_token or not secrets.compare_digest(
        x_scheduler_token,
        expected_token,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de scheduler invalido",
        )
