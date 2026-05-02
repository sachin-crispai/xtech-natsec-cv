import { useEffect } from "react";
import { useWebSocket } from "./hooks/useWebSocket";
import { useTrackStore } from "./store/useTrackStore";
import StatusBar from "./components/StatusBar";
import TacticalMap from "./components/TacticalMap";
import TrackPanel from "./components/TrackPanel";
import AlertFeed from "./components/AlertFeed";
import "./App.css";

export default function App() {
  useWebSocket();
  const setSensors = useTrackStore((s) => s.setSensors);

  useEffect(() => {
    fetch("http://localhost:8000/api/sensors/")
      .then((r) => r.json())
      .then(setSensors)
      .catch(() => {});
  }, []);

  return (
    <div className="app">
      <StatusBar />
      <div className="main-layout">
        <TrackPanel />
        <TacticalMap />
        <AlertFeed />
      </div>
    </div>
  );
}
