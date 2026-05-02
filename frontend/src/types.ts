export type SensorType = "EO" | "IR" | "RF";

export interface Track {
  track_id: string;
  lat: number;
  lon: number;
  confidence: number;
  sensor_types: SensorType[];
  first_seen: number;
  last_seen: number;
  is_evasion_candidate: boolean;
  evasion_score: number;
  status: "active" | "lost" | "confirmed";
}

export interface Alert {
  alert_id: string;
  track_id: string;
  alert_type: "new_track" | "track_lost" | "evasion_detected" | "multi_sensor_confirm";
  message: string;
  timestamp: number;
  severity: "info" | "warning" | "critical";
}

export interface Sensor {
  id: string;
  type: SensorType;
  status: "active" | "offline";
  lat: number;
  lon: number;
}
