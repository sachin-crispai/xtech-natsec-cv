from fastapi import APIRouter

router = APIRouter()

SENSOR_REGISTRY = [
    {"id": "EO-01", "type": "EO", "status": "active", "lat": 37.785, "lon": -122.400},
    {"id": "IR-01", "type": "IR", "status": "active", "lat": 37.790, "lon": -122.410},
    {"id": "RF-01", "type": "RF", "status": "active", "lat": 37.780, "lon": -122.395},
    {"id": "EO-02", "type": "EO", "status": "active", "lat": 37.788, "lon": -122.405},
]


@router.get("/")
async def list_sensors():
    return SENSOR_REGISTRY
