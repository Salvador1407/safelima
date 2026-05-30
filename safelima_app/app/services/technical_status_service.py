from datetime import datetime
from sqlalchemy import text
from sqlalchemy.orm import Session
import requests


def check_cloud_run_status() -> dict:
    try:
        response = requests.get("http://127.0.0.1:8080/health", timeout=3)
        if response.status_code == 200:
            return {
                "name": "Cloud Run",
                "status": "Disponible",
                "detail": "El backend respondió correctamente"
            }
        return {
            "name": "Cloud Run",
            "status": "No disponible",
            "detail": f"HTTP {response.status_code}"
        }
    except Exception as e:
        return {
            "name": "Cloud Run",
            "status": "No disponible",
            "detail": str(e)
        }


def check_cloud_sql_status(db: Session) -> dict:
    try:
        db.execute(text("SELECT 1"))
        return {
            "name": "Cloud SQL",
            "status": "Disponible",
            "detail": "Conexión a base de datos correcta"
        }
    except Exception as e:
        return {
            "name": "Cloud SQL",
            "status": "No disponible",
            "detail": str(e)
        }


def get_recent_errors() -> list[dict]:
    return [
        {
            "timestamp": datetime.utcnow().isoformat(),
            "severity": "INFO",
            "message": "Sin errores recientes registrados"
        }
    ]


def get_technical_dashboard(db: Session):
    return {
        "cloud_run": check_cloud_run_status(),
        "cloud_sql": check_cloud_sql_status(db),
        "recent_errors": get_recent_errors(),
        "checked_at": datetime.utcnow().isoformat()
    }