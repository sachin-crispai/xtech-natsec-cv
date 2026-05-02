from pydantic import BaseModel, Field
from typing import Literal
from enum import Enum
import time


class SensorType(str, Enum):
    EO = "EO"
    IR = "IR"
    RF = "RF"


class Detection(BaseModel):
    sensor_id: str
    sensor_type: SensorType
    timestamp: float = Field(default_factory=time.time)
    lat: float
    lon: float
    confidence: float = Field(ge=0.0, le=1.0)
    class_label: str = "unknown"
    bbox: list[float] | None = None
    signal_strength: float | None = None
    frequency_mhz: float | None = None


class Track(BaseModel):
    track_id: str
    detections: list[Detection] = []
    lat: float
    lon: float
    confidence: float
    sensor_types: list[SensorType] = []
    first_seen: float = Field(default_factory=time.time)
    last_seen: float = Field(default_factory=time.time)
    is_evasion_candidate: bool = False
    evasion_score: float = 0.0
    status: Literal["active", "lost", "confirmed"] = "active"


class Alert(BaseModel):
    alert_id: str
    track_id: str
    alert_type: Literal["new_track", "track_lost", "evasion_detected", "multi_sensor_confirm"]
    message: str
    timestamp: float = Field(default_factory=time.time)
    severity: Literal["info", "warning", "critical"] = "info"
