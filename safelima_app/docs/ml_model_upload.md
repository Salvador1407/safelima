# Subida de modelos ML a Google Cloud Storage

FastAPI no entrena modelos. Solo consume bundles `.pkl` ya entrenados con:

- `pipeline`
- `class_map`
- `risk_label_map`
- `features`

Rutas esperadas en GCS:

- `gs://safelima-ml-models/models/risk/batch/modelo_riesgo_batch.pkl`
- `gs://safelima-ml-models/models/risk/online/modelo_riesgo_online.pkl`

Bloque para Colab o entorno con ADC configurado:

```python
from google.cloud import storage

client = storage.Client()
bucket = client.bucket("safelima-ml-models")

bucket.blob("models/risk/batch/modelo_riesgo_batch.pkl").upload_from_filename(
    "modelo_riesgo_batch.pkl"
)

bucket.blob("models/risk/online/modelo_riesgo_online.pkl").upload_from_filename(
    "modelo_riesgo_online.pkl"
)
```

Features esperadas del bundle batch:

```python
[
    "anio",
    "mes",
    "dia",
    "dia_semana",
    "tramo_horario",
    "lugar_especifico",
]
```

Features esperadas del bundle online:

```python
[
    "anio",
    "mes",
    "dia",
    "dia_semana",
    "hora_decimal",
    "tramo_horario",
    "lugar_especifico",
    "tipo_incidente",
]
```

El modelo online debe recibir `tipo_incidente` con el label completo entrenado, por ejemplo `Robo de vehículo`, no con códigos cortos como `robo_vehiculo`.
