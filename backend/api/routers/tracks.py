from fastapi import APIRouter
from ...core.models import Track

router = APIRouter()

# In-memory store populated by the tracker — replace with Redis in prod
_track_store: dict[str, dict] = {}


def update_store(tracks: list[dict]):
    global _track_store
    _track_store = {t["track_id"]: t for t in tracks}


@router.get("/", response_model=list[Track])
async def list_tracks():
    return list(_track_store.values())


@router.get("/{track_id}", response_model=Track)
async def get_track(track_id: str):
    return _track_store.get(track_id)
