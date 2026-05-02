import { useEffect, useRef } from "react";
import { useTrackStore } from "../store/useTrackStore";

const WS_URL = "ws://localhost:8000/ws/tracks";

export function useWebSocket() {
  const { setTracks, addAlert, setWsConnected } = useTrackStore();
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    function connect() {
      const ws = new WebSocket(WS_URL);
      wsRef.current = ws;

      ws.onopen = () => setWsConnected(true);
      ws.onclose = () => {
        setWsConnected(false);
        setTimeout(connect, 2000);
      };
      ws.onerror = () => ws.close();

      ws.onmessage = (ev) => {
        try {
          const msg = JSON.parse(ev.data);
          if (msg.type === "state") setTracks(msg.tracks);
          if (msg.type === "alert") addAlert(msg);
        } catch {
          // ignore malformed messages
        }
      };
    }

    connect();
    return () => wsRef.current?.close();
  }, []);
}
