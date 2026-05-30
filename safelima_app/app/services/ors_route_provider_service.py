import os
import httpx
from fastapi import HTTPException
from dotenv import load_dotenv

#ORS Route Provider

load_dotenv()

ORS_API_KEY = (os.getenv("ORS_API_KEY") or "").strip()
ORS_DIRECTIONS_URL = (
    os.getenv(
        "ORS_DIRECTIONS_URL",
        "https://api.heigit.org/openrouteservice/v2/directions/driving-car",
    )
    or ""
).strip()


async def get_alternative_routes(
    origin_lat: float,
    origin_lon: float,
    destination_lat: float,
    destination_lon: float,
) -> dict:
    if not ORS_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="ORS_API_KEY no configurada en variables de entorno.",
        )

    headers = {
        "Authorization": ORS_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json, application/geo+json",
    }

    url_base = ORS_DIRECTIONS_URL.rstrip("/")
    url = url_base if url_base.endswith("/geojson") else f"{url_base}/geojson"

    coordinates = [
        [origin_lon, origin_lat],
        [destination_lon, destination_lat],
    ]

    payload_with_alternatives = {
        "coordinates": coordinates,
        "alternative_routes": {
            "target_count": 3,
            "share_factor": 0.6,
            "weight_factor": 1.4,
        },
        "instructions": False,
        "preference": "fastest",
        "units": "m",
        "geometry": True,
    }

    payload_simple = {
        "coordinates": coordinates,
        "instructions": False,
        "preference": "fastest",
        "units": "m",
        "geometry": True,
    }

    async def _post_ors(payload: dict) -> dict:
        timeout = httpx.Timeout(30.0, connect=10.0)

        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                url,
                json=payload,
                headers=headers,
            )

        if response.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f"ORS devolvió {response.status_code}: {response.text}",
            )

        data = response.json()

        if "features" not in data or not data["features"]:
            raise HTTPException(
                status_code=502,
                detail="ORS no devolvió rutas (features) válidas.",
            )

        return data

    try:
        return await _post_ors(payload_with_alternatives)

    except httpx.TimeoutException:
        try:
            return await _post_ors(payload_simple)
        except httpx.TimeoutException as e:
            raise HTTPException(
                status_code=504,
                detail="Timeout ORS: no se pudo calcular la ruta segura.",
            ) from e

    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=502,
            detail=f"Error HTTP ORS: {e}",
        ) from e