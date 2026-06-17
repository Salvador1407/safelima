import os

from dotenv import load_dotenv

#Config
load_dotenv()


class Settings:
    
    #Base de Datos
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@localhost:5432/safe_lima",
    )
    
    DATABASE_ECHO: bool = os.getenv("DATABASE_ECHO", "false").lower() == "true"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-me-local-dev-secret")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    TZ: str = os.getenv("TZ", "America/Lima")

    
    #Google Storage - Alertas con imagenes
    GCS_BUCKET_NAME: str = os.getenv("GCS_BUCKET_NAME", "safelima-evidencias")
    GCS_FOLDER_ALERTS: str = os.getenv("GCS_FOLDER_ALERTS", "user_alerts")
    GCS_PROJECT_ID: str = os.getenv("GCS_PROJECT_ID", "project-5e198772-9055-4366-a25")
    
    
    #Google Storage - Modelo Machine Learning
    ML_MODEL_SOURCE: str = os.getenv("ML_MODEL_SOURCE", "gcs")

    GCS_ML_BUCKET: str = os.getenv("GCS_ML_BUCKET", "safelima-ml-models")
    ML_BATCH_MODEL_BLOB: str = os.getenv(
        "ML_BATCH_MODEL_BLOB",
        "models/risk/batch/modelo_riesgo_batch.pkl",
    )
    ML_ONLINE_MODEL_BLOB: str = os.getenv(
        "ML_ONLINE_MODEL_BLOB",
        "models/risk/online/modelo_riesgo_online.pkl",
    )
    ML_LOCAL_DIR: str = os.getenv("ML_LOCAL_DIR", "/tmp/safelima_models")

    ML_BATCH_MODEL_PATH: str = os.getenv(
        "ML_BATCH_MODEL_PATH",
        "app/ml_models/modelo_riesgo_batch.pkl",
    )
    ML_ONLINE_MODEL_PATH: str = os.getenv(
        "ML_ONLINE_MODEL_PATH",
        "app/ml_models/modelo_riesgo_online.pkl",
    )


settings = Settings()
