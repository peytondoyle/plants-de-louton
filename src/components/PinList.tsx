import type { Pin } from "../types/types";

export default function PinList({ pins, onSelect }: { pins: Pin[]; onSelect: (pin: Pin) => void }) {
  return (
    <div className="pin-list">
      <div className="pin-list-title">Pins</div>
      {pins.length === 0 ? (
        <div className="pin-empty">No pins yet.</div>
      ) : (
        <ul>
          {pins.map((p) => (
            <li key={p.id}>
              <button onClick={() => onSelect(p)} title={`${Math.round(p.x*100)}%, ${Math.round(p.y*100)}%`}>
                {p.name}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}