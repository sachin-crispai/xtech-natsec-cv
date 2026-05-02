"""
Simulates EO, IR, and RF sensor feeds for demo purposes.
In production, replace with real sensor adapters.
"""
import asyncio
import random
import math
import time
import uuid

from ..core.event_bus import EventBus
from ..core.models import Detection, SensorType


# Simulated scenario: 4 targets moving across an AO, one actively evading
TARGETS = [
    {"id": "T1", "lat": 37.785, "lon": -122.400, "dlat": 0.0001, "dlon": 0.0002, "evading": False},
    {"id": "T2", "lat": 37.790, "lon": -122.410, "dlat": -0.0001, "dlon": 0.0001, "evading": False},
    {"id": "T3", "lat": 37.780, "lon": -122.395, "dlat": 0.0002, "dlon": -0.0001, "evading": True},
    {"id": "T4", "lat": 37.788, "lon": -122.405, "dlat": 0.0001, "dlon": 0.0001, "evading": False},
]

SENSORS = [
    {"id": "EO-01", "type": SensorType.EO, "coverage_radius": 0.01, "drop_rate": 0.1},
    {"id": "IR-01", "type": SensorType.IR, "coverage_radius": 0.015, "drop_rate": 0.15},
    {"id": "RF-01", "type": SensorType.RF, "coverage_radius": 0.02, "drop_rate": 0.2},
    {"id": "EO-02", "type": SensorType.EO, "coverage_radius": 0.01, "drop_rate": 0.12},
]


class SensorSimulator:
    def __init__(self, event_bus: EventBus):
        self.bus = event_bus
        self.tick = 0

    async def run(self):
        while True:
            self._step()
            await asyncio.sleep(0.5)
            self.tick += 1

    def _step(self):
        for target in TARGETS:
            # Evasion: random jitter + occasional dropout
            jitter = 0.0
            if target["evading"] and self.tick % 4 == 0:
                jitter = random.uniform(-0.002, 0.002)
                target["dlat"] = random.uniform(-0.0002, 0.0002)
                target["dlon"] = random.uniform(-0.0002, 0.0002)

            target["lat"] += target["dlat"] + jitter
            target["lon"] += target["dlon"] + jitter

        for sensor in SENSORS:
            for target in TARGETS:
                # Evading targets drop detections more often
                drop_rate = sensor["drop_rate"]
                if target["evading"]:
                    drop_rate += 0.35
                if random.random() < drop_rate:
                    continue

                noise_lat = random.gauss(0, 0.0002)
                noise_lon = random.gauss(0, 0.0002)

                detection = Detection(
                    sensor_id=sensor["id"],
                    sensor_type=sensor["type"],
                    timestamp=time.time(),
                    lat=target["lat"] + noise_lat,
                    lon=target["lon"] + noise_lon,
                    confidence=random.uniform(0.6, 0.99),
                    class_label="vehicle" if sensor["type"] != SensorType.RF else "emitter",
                    signal_strength=random.uniform(-80, -20) if sensor["type"] == SensorType.RF else None,
                    frequency_mhz=random.uniform(400, 450) if sensor["type"] == SensorType.RF else None,
                )
                self.bus.publish("detection", detection.model_dump())
