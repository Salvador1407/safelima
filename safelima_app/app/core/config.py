import os

from dotenv import load_dotenv

#Config
load_dotenv()


class Settings:
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@localhost:5432/safe_lima",
    )
    DATABASE_ECHO: bool = os.getenv("DATABASE_ECHO", "false").lower() == "true"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-me-local-dev-secret")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

    GCS_BUCKET_NAME: str = os.getenv("GCS_BUCKET_NAME", "safelima-evidencias")
    GCS_FOLDER_ALERTS: str = os.getenv("GCS_FOLDER_ALERTS", "user_alerts")
    GCS_PROJECT_ID: str = os.getenv("GCS_PROJECT_ID", "project-5e198772-9055-4366-a25")


settings = Settings()
