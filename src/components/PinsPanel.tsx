import type { Pin } from "../types/types";

type Props = {
  pins: Pin[];
  onAdd: () => void;
  onOpen: (pin: Pin) => void;
};

export default function PinsPanel({ pins, onAdd, onOpen }: Props) {
  return (
    <div className="card">
      <div className="panel">
        <div className="panel-head" style={{ marginBottom: 6 }}>
          <div className="panel-title">Pins</div>
          <div className="panel-meta">{pins.length}</div>
          <button
            type="button"
            className="ui-btn ui-btn--sm"
            onClick={onAdd}
            style={{ marginLeft: 8 }}
          >
            + Add
          </button>
        </div>

        {pins.length === 0 ? (
          <div className="panel-empty">
            No pins yet. Click “Add” or tap the image.
          </div>
        ) : (
          <ul className="pin-rows">
            {pins.map((p) => (
              <li key={p.id}>
                <button
                  type="button"
                  className="pin-row"
                  onClick={() => onOpen(p)}
                  title={p.name ?? undefined}
                >
                  <span className="pin-dot" />
                  <span className="pin-name">{p.name || "Untitled"}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}