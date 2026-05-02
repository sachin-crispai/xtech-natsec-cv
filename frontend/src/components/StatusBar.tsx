import { useTrackStore } from "../store/useTrackStore";

export default function StatusBar() {
  const { tracks, wsConnected } = useTrackStore();
  const trackList = Object.values(tracks);
  const active = trackList.filter((t) => t.status === "active").length;
  const evasion = trackList.filter((t) => t.is_evasion_candidate).length;
  const multiSensor = trackList.filter((t) => t.sensor_types.length >= 2).length;

  return (
    <div className="status-bar">
      <div className="status-title">
        <span className="logo">SensorFuse</span>
        <span className="subtitle">Multi-Sensor Fusion — xTech 2026</span>
      </div>
      <div className="status-metrics">
        <div className={`ws-status ${wsConnected ? "connected" : "disconnected"}`}>
          {wsConnected ? "● LIVE" : "○ OFFLINE"}
        </div>
        <div className="metric"><span className="val">{active}</span> Active Tracks</div>
        <div className="metric"><span className="val multi">{multiSensor}</span> Multi-Sensor</div>
        <div className="metric"><span className="val evasion">{evasion}</span> Evasion</div>
      </div>
    </div>
  );
}
