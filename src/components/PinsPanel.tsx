import type { Pin } from "../types/types";
import PlantGalleryStrip from "./plant-gallery/PlantGalleryStrip";
import React from "react";
import { getPinColors } from "../lib/pinColor";
import Tooltip from "./Tooltip/Tooltip";

type Props = {
  pins: Pin[];
  onOpen: (pin: Pin) => void;
  selectedPinId?: string;
  fullHeight?: number;
  onSelect?: (pin: Pin | null) => void;
  cardRef?: React.Ref<HTMLDivElement>;
  promoteSelected?: boolean;
  onToggleAddMode?: () => void;
  addMode?: boolean;
};

export default function PinsPanel({ pins, onOpen, selectedPinId, fullHeight, onSelect, cardRef, promoteSelected = false, onToggleAddMode, addMode = false }: Props) {
  const sortedPins = promoteSelected && selectedPinId
    ? [
        ...pins.filter(p => p.id === selectedPinId),
        ...pins.filter(p => p.id !== selectedPinId),
      ]
    : pins;
  return (
    <div className="card" ref={cardRef} style={fullHeight ? { height: fullHeight, display: 'flex', flexDirection: 'column' } : undefined}>
      <div className={`panel ${fullHeight ? 'panel--fill' : ''}`} style={fullHeight ? { flex: 1, display: 'flex', flexDirection: 'column' } : undefined}>

      <div className="panel-head">
        <div className="panel-title">Pins</div>
        <div className="panel-actions">
          <div className="panel-meta" title="Total pins">{pins.length}</div>
          <Tooltip content="How to use pins: Click the big image to add a pin. Click a pin dot to edit or delete it. Use the thumbnails above to switch images.">
            <button className="pill pill--icon" aria-label="Pin help">
              <svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="11" fill="currentColor" opacity=".08"/>
                <path d="M12 8.5a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm-1.1 2.7h2.2v6.3h-2.2z"
                      fill="currentColor"/>
              </svg>
            </button>
          </Tooltip>
          {onToggleAddMode ? (
            <button
              type="button"
              className={`ui-btn ui-btn--sm ${addMode ? 'is-active' : ''}`}
              onClick={onToggleAddMode}
              aria-pressed={addMode}
            >
              {addMode ? 'Exit add mode' : 'Add new pin'}
            </button>
          ) : null}
        </div>
      </div>

        {pins.length === 0 ? (
          <div className="panel-empty">
            No pins yet. Click the image to add a pin.
          </div>
        ) : (
          <ul className="pin-rows" style={fullHeight ? { flex: 1 } : undefined}>
            {sortedPins.map((p) => (
              <li key={p.id}>
                <button
                  type="button"
                  className={`pin-row ${selectedPinId === p.id ? 'is-selected' : ''}`}
                  onClick={(e) => { e.stopPropagation(); onSelect?.(selectedPinId === p.id ? null : p); }}
                  title={p.name ?? undefined}
                >
                  <span
                    className="pin-dot"
                    style={{
                      background: `radial-gradient(circle at 30% 30%, ${getPinColors(p.id).highlight} 0%, ${getPinColors(p.id).base} 70%)`,
                      borderColor: getPinColors(p.id).highlight,
                    }}
                  />
                  <span className="pin-name">{p.name || "Untitled"}</span>
                  <span className="pin-spacer" />
                  {p.plant_id ? (
                    <PlantGalleryStrip plantId={p.plant_id} onOpen={() => onOpen(p)} />
                  ) : null}
                  <span className="pin-edit-btn-wrap">
                    <button
                      type="button"
                      aria-label="Edit pin"
                      className="pin-edit"
                      onClick={(e) => { e.stopPropagation(); onOpen(p); }}
                      title="Edit pin"
                    >
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <path d="M12 20h9"/>
                        <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>
                      </svg>
                    </button>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}