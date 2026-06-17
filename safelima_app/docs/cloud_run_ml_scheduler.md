# Cloud Run ML Scheduler

Este backend mantiene dos rutas para batch ML:

- `POST /admin/ml/batch-predictions`: ejecucion manual protegida con JWT admin.
- `POST /internal/ml/batch-predictions`: ejecucion automatica protegida con `X-Scheduler-Token`.

No se debe guardar el token real en scripts, documentacion versionada ni commits.

## Variables base

PowerShell:

```powershell
$PROJECT_ID = "project-5e198772-9055-4366-a25"
$REGION = "us-central1"
$REPO_NAME = "backend-repo"
$SERVICE_NAME = "safelima-backend"
$IMAGE_NAME = "safelima-backend"
$VERSION = "vX"
$IMAGE_URI = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${VERSION}"
```

## Build principal

Ejecutar desde `C:\SafeLima\safelima_app`:

```powershell
gcloud builds submit --tag $IMAGE_URI
```

El `Dockerfile` usa `python:3.13-slim` porque los `.pkl` fueron validados
con Python 3.13.7. Si Cloud Build falla instalando dependencias, la alternativa
es mantener una version Python compatible en el contenedor, regenerar los `.pkl`
con esa version y volver a subirlos a GCS.

## Secret Manager

Generar un token largo y aleatorio fuera del repositorio. Guardarlo como secreto:

```powershell
gcloud secrets create safelima-scheduler-token --data-file=-
```

Dar acceso al service account de Cloud Run:

```powershell
gcloud secrets add-iam-policy-binding safelima-scheduler-token `
  --member="serviceAccount:<CLOUD_RUN_SERVICE_ACCOUNT>" `
  --role="roles/secretmanager.secretAccessor"
```

## Permisos GCS para modelos

```powershell
gcloud storage buckets add-iam-policy-binding gs://safelima-ml-models `
  --member="serviceAccount:<CLOUD_RUN_SERVICE_ACCOUNT>" `
  --role="roles/storage.objectViewer"
```

## Deploy principal

```powershell
gcloud run deploy $SERVICE_NAME `
  --image $IMAGE_URI `
  --region $REGION `
  --allow-unauthenticated `
  --memory 1Gi `
  --cpu 1 `
  --timeout 900 `
  --concurrency 20 `
  --cpu-boost `
  --set-env-vars "ML_MODEL_SOURCE=gcs,TZ=America/Lima,GCS_PROJECT_ID=$PROJECT_ID,GCS_ML_BUCKET=safelima-ml-models,ML_LOCAL_DIR=/tmp/safelima_models,ML_BATCH_MODEL_BLOB=models/risk/batch/modelo_riesgo_batch.pkl,ML_ONLINE_MODEL_BLOB=models/risk/online/modelo_riesgo_online.pkl" `
  --update-secrets "SCHEDULER_TOKEN=safelima-scheduler-token:latest"
```

## Cloud Scheduler 3 AM Lima

Crear el job con zona horaria Lima. Reemplazar el valor del header manualmente
sin guardar el token en archivos versionados:

```powershell
gcloud scheduler jobs create http safelima-ml-batch-3am `
  --location $REGION `
  --schedule "0 3 * * *" `
  --time-zone "America/Lima" `
  --uri "https://<CLOUD_RUN_URL>/internal/ml/batch-predictions" `
  --http-method POST `
  --headers "X-Scheduler-Token=<TOKEN_CONFIGURADO_MANUALMENTE>"
```

## Validacion

```powershell
curl -H "Authorization: Bearer <ADMIN_JWT>" `
  https://<CLOUD_RUN_URL>/admin/ml/models/status

curl -X POST -H "Authorization: Bearer <ADMIN_JWT>" `
  https://<CLOUD_RUN_URL>/admin/ml/batch-predictions

curl -X POST -H "X-Scheduler-Token: <TOKEN>" `
  https://<CLOUD_RUN_URL>/internal/ml/batch-predictions

gcloud scheduler jobs run safelima-ml-batch-3am --location $REGION

gcloud run services logs read $SERVICE_NAME --region $REGION --limit 100
```
