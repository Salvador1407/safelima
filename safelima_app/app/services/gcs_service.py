from uuid import uuid4
from google.cloud import storage
from fastapi import UploadFile
from app.core.config import settings

# En storage_service.py
def upload_alert_image(file: UploadFile, citizen_id: int) -> str:
    # Asegúrate de que el cliente use el proyecto de cuota si es necesario
    client = storage.Client(settings.GCS_PROJECT_ID) 
    bucket = client.bucket(settings.GCS_BUCKET_NAME)

    extension = ""
    if file.filename and "." in file.filename:
        extension = "." + file.filename.split(".")[-1].lower()

    blob_name = f"{settings.GCS_FOLDER_ALERTS}/citizen_{citizen_id}/{uuid4().hex}{extension}"
    blob = bucket.blob(blob_name)

    # CORRECCIÓN: Asegurar que el puntero esté al inicio antes de leer
    file.file.seek(0) 
    content = file.file.read() 
    
    blob.upload_from_string(
        content,
        content_type=file.content_type
    )

    return f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_name}"