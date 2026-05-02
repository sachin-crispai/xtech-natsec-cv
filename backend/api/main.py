from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import logging

from ..core.event_bus import EventBus
from ..fusion.tracker import MultiSensorTracker
from ..sensors.simulator import SensorSimulator
from .routers import tracks, sensors, alerts

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="SensorFuse API",
    description="Multi-sensor fusion for real-time target tracking",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tracks.router, prefix="/api/tracks", tags=["tracks"])
app.include_router(sensors.router, prefix="/api/sensors", tags=["sensors"])
app.include_router(alerts.router, prefix="/api/alerts", tags=["alerts"])

event_bus = EventBus()
tracker = MultiSensorTracker(event_bus)
simulator = SensorSimulator(event_bus)

connected_clients: list[WebSocket] = []


@app.on_event("startup")
async def startup():
    asyncio.create_task(simulator.run())
    asyncio.create_task(tracker.run())
    asyncio.create_task(broadcast_loop())
    logger.info("SensorFuse backend started")


async def broadcast_loop():
    async for update in event_bus.subscribe("track_update"):
        dead = []
        for ws in connected_clients:
            try:
                await ws.send_text(json.dumps(update))
            except Exception:
                dead.append(ws)
        for ws in dead:
            connected_clients.remove(ws)


@app.websocket("/ws/tracks")
async def websocket_tracks(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        connected_clients.remove(websocket)


@app.get("/health")
async def health():
    return {"status": "ok", "tracks": tracker.active_track_count()}
