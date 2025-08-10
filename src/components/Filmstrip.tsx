import React from "react";
import useEmblaCarousel from "embla-carousel-react";
import type { Pin } from "../types/types";

type FilmstripItem = { id: string; url: string; label?: string };
type Props = {
  items: FilmstripItem[];
  activeId?: string;
  mainImageId?: string;
  onSelect: (id: string) => void;
  onDelete?: (imageId: string) => void;
  onSetMain?: (imageId: string) => void;
  pins?: Pin[];
  bedId?: string;
};

export default function Filmstrip({ 
  items, 
  activeId, 
  mainImageId,
  onSelect, 
  onDelete,
  onSetMain,
  pins = [],
  bedId
}: Props) {
  const [viewportRef, embla] = useEmblaCarousel({ 
    dragFree: true, 
    containScroll: "trimSnaps",
    align: "start",
    skipSnaps: false,
    inViewThreshold: 0.7
  });

  return (
    <div className="filmstrip-wrap">
      <div className="image-history sidebar-filmstrip" ref={viewportRef}>
        <div className="embla__container" style={{ display: "flex", gap: 10 }}>
          {items.map((it) => {
            const imagePins = pins.filter(pin => pin.image_id === it.id);
            const pinCount = imagePins.length;
            const isMain = it.id === mainImageId;
            const isActive = it.id === activeId;

            return (
              <div key={it.id} className="hist-thumb-wrapper" style={{ flex: "0 0 auto", width: 180 }}>
                <button
                  className={`hist-thumb ${isActive ? "active" : ""}`}
                  onClick={() => onSelect(it.id)}
                  style={{ aspectRatio: "4 / 3" }}
                  aria-current={isActive ? "true" : undefined}
                >
                  <img src={it.url} alt={it.label ?? ""} />
                  
                  {/* Clean, simple pin count indicator */}
                  <div className="pin-count-badge" title={`${pinCount} pin${pinCount === 1 ? '' : 's'}`}>
                    <span>{pinCount}</span>
                  </div>

                  {/* Main image indicator - only on the actual main image */}
                  {isMain && (
                    <div className="main-image-badge" title="Main image">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="currentColor"/>
                      </svg>
                    </div>
                  )}

                  {/* Date label */}
                  {it.label && <div className="hist-meta">{it.label}</div>}
                </button>

                {/* Clean action buttons - positioned to avoid layering issues */}
                <div className="hist-actions">
                  {!isMain && onSetMain && (
                    <button
                      type="button"
                      className="hist-action-btn hist-action-main"
                      onClick={() => onSetMain(it.id)}
                      title="Set as main image"
                      aria-label="Set as main image"
                    >
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="currentColor"/>
                      </svg>
                    </button>
                  )}
                  
                  {onDelete && (
                    <button
                      type="button"
                      className="hist-action-btn hist-action-delete"
                      onClick={() => onDelete(it.id)}
                      title="Delete image"
                      aria-label="Delete image"
                    >
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" fill="currentColor"/>
                      </svg>
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}


