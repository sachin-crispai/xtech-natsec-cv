import { useTrackStore } from "../store/useTrackStore";

export default function TrackPanel() {
  const { tracks, selectedTrackId, selectTrack } = useTrackStore();
  const trackList = Object.values(tracks).sort((a, b) => b.last_seen - a.last_seen);

  return (
    <div className="track-panel">
      <h3>Active Tracks ({trackList.length})</h3>
      <div className="track-list">
        {trackList.map((t) => (
          <div
            key={t.track_id}
            className={`track-item ${selectedTrackId === t.track_id ? "selected" : ""} ${t.is_evasion_candidate ? "evasion" : ""}`}
            onClick={() => selectTrack(t.track_id)}
          >
            <div className="track-header">
              <span className="track-id">{t.track_id}</span>
              <span className={`track-status ${t.status}`}>{t.status.toUpperCase()}</span>
            </div>
            <div className="track-sensors">
              {t.sensor_types.map((s) => (
                <span key={s} className={`sensor-badge ${s}`}>{s}</span>
              ))}
            </div>
            <div className="track-meta">
              <span>Conf: {(t.confidence * 100).toFixed(0)}%</span>
              {t.is_evasion_candidate && (
                <span className="evasion-badge">EVADING {(t.evasion_score * 100).toFixed(0)}%</span>
              )}
            </div>
          </div>
        ))}
        {trackList.length === 0 && <div className="no-tracks">Waiting for detections…</div>}
      </div>
    </div>
  );
}
