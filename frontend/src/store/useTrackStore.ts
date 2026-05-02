import { create } from "zustand";
import { Track, Alert, Sensor } from "../types";

interface TrackStore {
  tracks: Record<string, Track>;
  alerts: Alert[];
  sensors: Sensor[];
  selectedTrackId: string | null;
  wsConnected: boolean;
  setTracks: (tracks: Track[]) => void;
  addAlert: (alert: Alert) => void;
  setSensors: (sensors: Sensor[]) => void;
  selectTrack: (id: string | null) => void;
  setWsConnected: (v: boolean) => void;
}

export const useTrackStore = create<TrackStore>((set) => ({
  tracks: {},
  alerts: [],
  sensors: [],
  selectedTrackId: null,
  wsConnected: false,
  setTracks: (tracks) =>
    set({ tracks: Object.fromEntries(tracks.map((t) => [t.track_id, t])) }),
  addAlert: (alert) =>
    set((s) => ({ alerts: [alert, ...s.alerts].slice(0, 100) })),
  setSensors: (sensors) => set({ sensors }),
  selectTrack: (id) => set({ selectedTrackId: id }),
  setWsConnected: (v) => set({ wsConnected: v }),
}));
