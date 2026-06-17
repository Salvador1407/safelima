import logging
from pathlib import Path
from threading import Lock
from typing import Any

import joblib
from google.cloud import storage

from app.core.config import settings
from app.services.ml_feature_service import BATCH_FEATURES, ONLINE_FEATURES


logger = logging.getLogger(__name__)

REQUIRED_BUNDLE_KEYS = ("pipeline", "class_map", "risk_label_map", "features")


class MLModelLoadError(RuntimeError):
    pass


class MLModelLoader:
    def __init__(self) -> None:
        self._lock = Lock()
        self._batch_bundle: dict[str, Any] | None = None
        self._online_bundle: dict[str, Any] | None = None
        self._loaded = False
        self._errors: dict[str, str] = {}

    def load_models(self, force: bool = False) -> None:
        with self._lock:
            if self._loaded and not force:
                return

            self._errors = {}
            try:
                batch_path, online_path = self._resolve_model_paths()
                batch_bundle = self._load_and_validate_bundle(
                    batch_path,
                    expected_features=BATCH_FEATURES,
                    name="batch",
                )
                online_bundle = self._load_and_validate_bundle(
                    online_path,
                    expected_features=ONLINE_FEATURES,
                    name="online",
                )
            except Exception as exc:
                self._batch_bundle = None
                self._online_bundle = None
                self._loaded = False
                self._errors["load"] = str(exc)
                logger.exception("No se pudieron cargar los modelos ML: %s", exc)
                raise MLModelLoadError(str(exc)) from exc

            self._batch_bundle = batch_bundle
            self._online_bundle = online_bundle
            self._loaded = True
            logger.info("Modelos ML batch y online cargados correctamente")

    def get_batch_bundle(self) -> dict[str, Any]:
        self._ensure_loaded()
        if self._batch_bundle is None:
            raise MLModelLoadError("Modelo batch no disponible")
        return self._batch_bundle

    def get_online_bundle(self) -> dict[str, Any]:
        self._ensure_loaded()
        if self._online_bundle is None:
            raise MLModelLoadError("Modelo online no disponible")
        return self._online_bundle

    def status(self) -> dict[str, Any]:
        return {
            "source": settings.ML_MODEL_SOURCE,
            "loaded": self._loaded,
            "batch_loaded": self._batch_bundle is not None,
            "online_loaded": self._online_bundle is not None,
            "errors": self._errors,
            "gcs_bucket": settings.GCS_ML_BUCKET,
            "batch_model_blob": settings.ML_BATCH_MODEL_BLOB,
            "online_model_blob": settings.ML_ONLINE_MODEL_BLOB,
            "local_dir": settings.ML_LOCAL_DIR,
            "batch_model_path": settings.ML_BATCH_MODEL_PATH,
            "online_model_path": settings.ML_ONLINE_MODEL_PATH,
        }

    def _ensure_loaded(self) -> None:
        if not self._loaded:
            self.load_models()

    def _resolve_model_paths(self) -> tuple[Path, Path]:
        source = (settings.ML_MODEL_SOURCE or "gcs").strip().lower()

        if source == "local":
            return Path(settings.ML_BATCH_MODEL_PATH), Path(settings.ML_ONLINE_MODEL_PATH)

        if source == "gcs":
            local_dir = Path(settings.ML_LOCAL_DIR)
            local_dir.mkdir(parents=True, exist_ok=True)
            batch_path = local_dir / "modelo_riesgo_batch.pkl"
            online_path = local_dir / "modelo_riesgo_online.pkl"

            client = storage.Client(settings.GCS_PROJECT_ID)
            bucket = client.bucket(settings.GCS_ML_BUCKET)
            bucket.blob(settings.ML_BATCH_MODEL_BLOB).download_to_filename(str(batch_path))
            bucket.blob(settings.ML_ONLINE_MODEL_BLOB).download_to_filename(str(online_path))
            return batch_path, online_path

        raise MLModelLoadError("ML_MODEL_SOURCE debe ser local o gcs")

    def _load_and_validate_bundle(
        self,
        path: Path,
        *,
        expected_features: list[str],
        name: str,
    ) -> dict[str, Any]:
        if not path.exists():
            raise MLModelLoadError(f"Modelo {name} no encontrado en {path}")

        bundle = joblib.load(path)
        if not isinstance(bundle, dict):
            raise MLModelLoadError(f"Bundle {name} debe ser un dict")

        missing_keys = [key for key in REQUIRED_BUNDLE_KEYS if key not in bundle]
        if missing_keys:
            raise MLModelLoadError(
                f"Bundle {name} incompleto. Faltan claves: {', '.join(missing_keys)}"
            )

        pipeline = bundle["pipeline"]
        if not hasattr(pipeline, "predict"):
            raise MLModelLoadError(f"Bundle {name} no contiene un pipeline predictivo válido")

        features = list(bundle["features"])
        if features != expected_features:
            raise MLModelLoadError(
                f"Features de {name} no coinciden. Esperado {expected_features}, recibido {features}"
            )

        if not isinstance(bundle["class_map"], dict):
            raise MLModelLoadError(f"class_map de {name} debe ser dict")
        if not isinstance(bundle["risk_label_map"], dict):
            raise MLModelLoadError(f"risk_label_map de {name} debe ser dict")

        return bundle


model_loader = MLModelLoader()


def load_models(force: bool = False) -> None:
    model_loader.load_models(force=force)


def get_batch_bundle() -> dict[str, Any]:
    return model_loader.get_batch_bundle()


def get_online_bundle() -> dict[str, Any]:
    return model_loader.get_online_bundle()


def get_status() -> dict[str, Any]:
    return model_loader.status()

