"""
Multi-sensor track fusion using nearest-neighbor association + Kalman filtering.
Each track maintains fused position estimates across EO, IR, and RF detections.
"""
import asyncio
import math
import time
import uuid
from collections import defaultdict

from ..core.event_bus import EventBus
from ..core.models import Detection, Track, SensorType

ASSOCIATION_THRESHOLD_DEG = 0.003   # ~300m at mid-latitudes
TRACK_TIMEOUT_SEC = 10.0
EVASION_WINDOW_SEC = 30.0
EVASION_DROPOUT_THRESHOLD = 0.6    # >60% expected detections missing → evasion candidate


class KalmanTrack:
    def __init__(self, detection: Detection):
        self.track_id = str(uuid.uuid4())[:8]
        self.lat = detection.lat
        self.lon = detection.lon
        self.vlat = 0.0
        self.vlon = 0.0
        self.confidence = detection.confidence
        self.sensor_types: set[SensorType] = {detection.sensor_type}
        self.detections: list[dict] = [detection.model_dump()]
        self.first_seen = detection.timestamp
        self.last_seen = detection.timestamp
        self.detection_history: list[float] = [detection.timestamp]
        self.is_evasion_candidate = False
        self.evasion_score = 0.0

    def update(self, detection: Detection):
        dt = detection.timestamp - self.last_seen
        alpha = 0.3   # measurement weight
        self.lat = alpha * detection.lat + (1 - alpha) * (self.lat + self.vlat * dt)
        self.lon = alpha * detection.lon + (1 - alpha) * (self.lon + self.vlon * dt)
        if dt > 0:
            self.vlat = 0.7 * self.vlat + 0.3 * (detection.lat - self.lat) / dt
            self.vlon = 0.7 * self.vlon + 0.3 * (detection.lon - self.lon) / dt
        self.confidence = 0.4 * detection.confidence + 0.6 * self.confidence
        self.sensor_types.add(detection.sensor_type)
        self.last_seen = detection.timestamp
        self.detection_history.append(detection.timestamp)
        self.detections.append(detection.model_dump())

    def compute_evasion_score(self, expected_rate: float = 2.0):
        now = time.time()
        window_start = now - EVASION_WINDOW_SEC
        recent = [t for t in self.detection_history if t >= window_start]
        expected = expected_rate * EVASION_WINDOW_SEC
        if expected == 0:
            return 0.0
        dropout_ratio = 1.0 - (len(recent) / expected)
        self.evasion_score = max(0.0, min(1.0, dropout_ratio))
        self.is_evasion_candidate = self.evasion_score > EVASION_DROPOUT_THRESHOLD
        return self.evasion_score

    def to_track(self) -> Track:
        return Track(
            track_id=self.track_id,
            lat=self.lat,
            lon=self.lon,
            confidence=self.confidence,
            sensor_types=list(self.sensor_types),
            first_seen=self.first_seen,
            last_seen=self.last_seen,
            is_evasion_candidate=self.is_evasion_candidate,
            evasion_score=self.evasion_score,
            status="active" if (time.time() - self.last_seen) < TRACK_TIMEOUT_SEC else "lost",
        )


def haversine_deg(lat1, lon1, lat2, lon2) -> float:
    return math.sqrt((lat1 - lat2) ** 2 + (lon1 - lon2) ** 2)


class MultiSensorTracker:
    def __init__(self, event_bus: EventBus):
        self.bus = event_bus
        self.tracks: dict[str, KalmanTrack] = {}

    def active_track_count(self) -> int:
        return sum(1 for t in self.tracks.values() if time.time() - t.last_seen < TRACK_TIMEOUT_SEC)

    async def run(self):
        async for detection_dict in self.bus.subscribe("detection"):
            detection = Detection(**detection_dict)
            self._associate(detection)
            self._prune()
            self._publish_state()

    def _associate(self, detection: Detection):
        best_track = None
        best_dist = ASSOCIATION_THRESHOLD_DEG

        for track in self.tracks.values():
            if time.time() - track.last_seen > TRACK_TIMEOUT_SEC:
                continue
            d = haversine_deg(track.lat, track.lon, detection.lat, detection.lon)
            if d < best_dist:
                best_dist = d
                best_track = track

        if best_track:
            best_track.update(detection)
            best_track.compute_evasion_score()
            if len(best_track.sensor_types) >= 2:
                self.bus.publish("alert", {
                    "alert_id": str(uuid.uuid4())[:8],
                    "track_id": best_track.track_id,
                    "alert_type": "multi_sensor_confirm",
                    "message": f"Track {best_track.track_id} confirmed by {len(best_track.sensor_types)} sensor types",
                    "timestamp": time.time(),
                    "severity": "info",
                })
            if best_track.is_evasion_candidate:
                self.bus.publish("alert", {
                    "alert_id": str(uuid.uuid4())[:8],
                    "track_id": best_track.track_id,
                    "alert_type": "evasion_detected",
                    "message": f"Track {best_track.track_id} showing evasion behavior (score={best_track.evasion_score:.2f})",
                    "timestamp": time.time(),
                    "severity": "critical",
                })
        else:
            new_track = KalmanTrack(detection)
            self.tracks[new_track.track_id] = new_track
            self.bus.publish("alert", {
                "alert_id": str(uuid.uuid4())[:8],
                "track_id": new_track.track_id,
                "alert_type": "new_track",
                "message": f"New track {new_track.track_id} detected by {detection.sensor_type}",
                "timestamp": time.time(),
                "severity": "info",
            })

    def _prune(self):
        cutoff = time.time() - TRACK_TIMEOUT_SEC * 3
        dead = [tid for tid, t in self.tracks.items() if t.last_seen < cutoff]
        for tid in dead:
            del self.tracks[tid]

    def _publish_state(self):
        tracks_out = [t.to_track().model_dump() for t in self.tracks.values()]
        self.bus.publish("track_update", {"type": "state", "tracks": tracks_out, "ts": time.time()})
