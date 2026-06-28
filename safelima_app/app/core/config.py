import os

from dotenv import load_dotenv

#Config
load_dotenv()

#Migrado
class Settings:
    
    #Base de Datos
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    
    DATABASE_ECHO: bool = os.getenv("DATABASE_ECHO", "false").lower() == "true"
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    SCHEDULER_TOKEN: str | None = os.getenv("SCHEDULER_TOKEN")
    TZ: str = os.getenv("TZ", "America/Lima")

    
    #Google Storage - Alertas con imagenes
    GCS_BUCKET_NAME: str = os.getenv("GCS_BUCKET_NAME")
    GCS_FOLDER_ALERTS: str = os.getenv("GCS_FOLDER_ALERTS")
    GCS_PROJECT_ID: str = os.getenv("GCS_PROJECT_ID")
    
    
    #Google Storage - Modelo Machine Learning
    ML_MODEL_SOURCE: str = os.getenv("ML_MODEL_SOURCE", "gcs")
    GCS_ML_BUCKET: str = os.getenv("GCS_ML_BUCKET")
    ML_BATCH_MODEL_BLOB: str = os.getenv("ML_BATCH_MODEL_BLOB")
    
    ML_ONLINE_MODEL_BLOB: str = os.getenv("ML_ONLINE_MODEL_BLOB")
    ML_LOCAL_DIR: str = os.getenv("ML_LOCAL_DIR")

    ML_BATCH_MODEL_PATH: str = os.getenv("ML_BATCH_MODEL_PATH")
    ML_ONLINE_MODEL_PATH: str = os.getenv("ML_ONLINE_MODEL_PATH")

settings = Settings()
