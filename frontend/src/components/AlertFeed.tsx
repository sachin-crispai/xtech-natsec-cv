import { useTrackStore } from "../store/useTrackStore";

const SEVERITY_STYLE: Record<string, string> = {
  critical: "#ff2244",
  warning: "#ffaa00",
  info: "#4fa3e0",
};

function timeAgo(ts: number) {
  const diff = Date.now() / 1000 - ts;
  if (diff < 60) return `${Math.floor(diff)}s ago`;
  return `${Math.floor(diff / 60)}m ago`;
}

export default function AlertFeed() {
  const alerts = useTrackStore((s) => s.alerts);

  return (
    <div className="alert-feed">
      <h3>Alert Feed</h3>
      <div className="alert-list">
        {alerts.map((a) => (
          <div key={a.alert_id} className="alert-item" style={{ borderLeft: `3px solid ${SEVERITY_STYLE[a.severity]}` }}>
            <span className="alert-type">{a.alert_type.replace(/_/g, " ").toUpperCase()}</span>
            <span className="alert-msg">{a.message}</span>
            <span className="alert-time">{timeAgo(a.timestamp)}</span>
          </div>
        ))}
        {alerts.length === 0 && <div className="no-alerts">No alerts</div>}
      </div>
    </div>
  );
}
