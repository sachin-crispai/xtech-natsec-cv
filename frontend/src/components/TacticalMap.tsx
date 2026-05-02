import { MapContainer, TileLayer, CircleMarker, Popup, Tooltip } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import { useTrackStore } from "../store/useTrackStore";
import clsx from "clsx";

const SENSOR_COLORS: Record<string, string> = {
  EO: "#00ff88",
  IR: "#ff6b35",
  RF: "#4fa3e0",
};

function trackColor(track: { is_evasion_candidate: boolean; sensor_types: string[]; status: string }) {
  if (track.is_evasion_candidate) return "#ff2244";
  if (track.sensor_types.length >= 2) return "#ffdd00";
  return "#00aaff";
}

export default function TacticalMap() {
  const { tracks, sensors, selectTrack, selectedTrackId } = useTrackStore();
  const trackList = Object.values(tracks);

  return (
    <div className="tactical-map">
      <MapContainer
        center={[37.785, -122.402]}
        zoom={14}
        style={{ height: "100%", width: "100%", background: "#0d1117" }}
      >
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; <a href="https://carto.com/">CARTO</a>'
        />

        {/* Sensor positions */}
        {sensors.map((s) => (
          <CircleMarker
            key={s.id}
            center={[s.lat, s.lon]}
            radius={6}
            pathOptions={{ color: SENSOR_COLORS[s.type] ?? "#fff", fillOpacity: 0.9 }}
          >
            <Tooltip permanent>{s.id}</Tooltip>
          </CircleMarker>
        ))}

        {/* Tracks */}
        {trackList.map((t) => (
          <CircleMarker
            key={t.track_id}
            center={[t.lat, t.lon]}
            radius={t.is_evasion_candidate ? 14 : 10}
            pathOptions={{
              color: trackColor(t),
              fillColor: trackColor(t),
              fillOpacity: 0.8,
              weight: t.track_id === selectedTrackId ? 3 : 1,
            }}
            eventHandlers={{ click: () => selectTrack(t.track_id) }}
          >
            <Popup>
              <div style={{ fontFamily: "monospace", fontSize: 12 }}>
                <b>Track {t.track_id}</b><br />
                Status: {t.status}<br />
                Confidence: {(t.confidence * 100).toFixed(0)}%<br />
                Sensors: {t.sensor_types.join(", ")}<br />
                Evasion Score: {(t.evasion_score * 100).toFixed(0)}%<br />
                {t.is_evasion_candidate && <span style={{ color: "#ff2244" }}>⚠ EVASION DETECTED</span>}
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>

      <div className="map-legend">
        <div><span style={{ color: "#ffdd00" }}>●</span> Multi-sensor</div>
        <div><span style={{ color: "#00aaff" }}>●</span> Single-sensor</div>
        <div><span style={{ color: "#ff2244" }}>●</span> Evasion</div>
      </div>
    </div>
  );
}
