import type { Pin } from "../types/types";
import Tooltip from "./Tooltip";

type Props = {
  pins: Pin[];
  onAdd: () => void;
  onOpen: (pin: Pin) => void;
};

export default function PinsPanel({ pins, onAdd, onOpen }: Props) {
  return (
    <div className="card">
      <div className="panel">

      <div className="panel-head">
        <div className="panel-title">Pins</div>
        <div className="panel-meta">{pins.length}</div>
        <button className="panel-action" onClick={onAdd}>+ Add</button>

        <Tooltip label="Pin help">
          <svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="11" fill="currentColor" opacity=".08"/>
            <path d="M12 8.5a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm-1.1 2.7h2.2v6.3h-2.2z"
                  fill="currentColor"/>
          </svg>
        </Tooltip>
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