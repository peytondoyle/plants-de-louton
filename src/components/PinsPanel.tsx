import type { Pin } from "../types/types";

export default function PinsPanel({
  pins,
  onAdd,
  onOpen,
}: {
  pins: Pin[];
  onAdd: () => void;
  onOpen: (pin: Pin) => void;
}) {
  return (
    <div className="panel card">
      <div className="panel-head">
        <div className="panel-title">Pins</div>
        <div className="panel-meta">{pins.length}</div>
        <button className="panel-action" onClick={onAdd}>+ Add</button>
      </div>

      {pins.length === 0 ? (
        <div className="panel-empty">
          No pins yet. Click “Add” or tap the image.
        </div>
      ) : (
        <ul className="pin-rows">
          {pins.map((p) => (
            <li key={p.id}>
              <button className="pin-row" onClick={() => onOpen(p)}>
                <span className="pin-dot" />
                <span className="pin-name">{p.name}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}