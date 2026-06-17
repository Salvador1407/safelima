from fastapi import APIRouter, FastAPI
from app.database.database import Base, engine
from dotenv import load_dotenv
load_dotenv()

from app.controllers import (
    user_controller,
    citizen_controller,
    grid_controller,
    favorite_area_controller,
    dataset_controller,
    ml_model_controller,
    prediction_grid_controller,
    user_alert_controller,
    zone_review_controller,
    review_like_controller,
    police_station_controller,
    app_feedback_controller,
    admin_technical_router,
    ml_admin_controller,
    safe_route_controller,
)
from app.services import ml_model_loader_service

# Inicializar FastAPI
app = FastAPI(
    title="SafeLima API",
    version="1.0",
    description="API para el sistema de predicción y visualización de zonas inseguras en Lima Metropolitana."
)

# Incluir routers (endpoints principales)
app.include_router(user_controller.router)
app.include_router(citizen_controller.router)
app.include_router(grid_controller.router)
app.include_router(favorite_area_controller.router)
app.include_router(dataset_controller.router)
app.include_router(ml_model_controller.router)
app.include_router(prediction_grid_controller.router)
app.include_router(user_alert_controller.router)
app.include_router(zone_review_controller.router)
app.include_router(review_like_controller.router)
app.include_router(police_station_controller.router)
app.include_router(app_feedback_controller.router)
app.include_router(admin_technical_router.router)
app.include_router(ml_admin_controller.router)
app.include_router(safe_route_controller.router)


@app.on_event("startup")
def load_ml_models_on_startup():
    try:
        ml_model_loader_service.load_models()
    except Exception as exc:
        print(f"Error cargando modelos ML: {exc}")

# Endpoint base de verificación
@app.get("/")
def root():
    return {"message": "🚀 SafeLima API funcionando correctamente."}

@app.get("/health")
def health_check():
    return {"status": "ok"}
