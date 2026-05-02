from fastapi import APIRouter
from collections import deque
from ...core.models import Alert

router = APIRouter()

alert_queue: deque[dict] = deque(maxlen=200)


def push_alert(alert: dict):
    alert_queue.appendleft(alert)


@router.get("/", response_model=list[Alert])
async def list_alerts(limit: int = 50):
    return list(alert_queue)[:limit]
