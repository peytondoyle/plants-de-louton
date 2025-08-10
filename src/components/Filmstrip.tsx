import React, { useCallback, useEffect, useState } from "react";
import useEmblaCarousel from "embla-carousel-react";
import Tooltip from "./Tooltip";

type FilmstripItem = { id: string; url: string; label?: string };
type Props = {
  items: FilmstripItem[];
  activeId?: string;
  onSelect: (id: string) => void;
};

export default function Filmstrip({ items, activeId, onSelect }: Props) {
  const [viewportRef, embla] = useEmblaCarousel({ dragFree: true, containScroll: "trimSnaps" });
  const [canPrev, setCanPrev] = useState(false);
  const [canNext, setCanNext] = useState(false);

  const updateButtons = useCallback(() => {
    if (!embla) return;
    setCanPrev(embla.canScrollPrev());
    setCanNext(embla.canScrollNext());
  }, [embla]);

  useEffect(() => {
    if (!embla) return;
    embla.on("reInit", updateButtons);
    embla.on("select", updateButtons);
    updateButtons();
  }, [embla, updateButtons]);

  return (
    <div className="filmstrip-wrap">
      <Tooltip label="Previous">
        <button className="filmstrip-arrow left" onClick={() => embla?.scrollPrev()} disabled={!canPrev}>‹</button>
      </Tooltip>

      <div className="image-history sidebar-filmstrip" ref={viewportRef}>
        <div className="embla__container" style={{ display: "flex", gap: 10 }}>
          {items.map((it) => (
            <button
              key={it.id}
              className={`hist-thumb ${activeId === it.id ? "active" : ""}`}
              onClick={() => onSelect(it.id)}
              style={{ flex: "0 0 auto", width: 180, aspectRatio: "4 / 3" }}
              aria-current={activeId === it.id ? "true" : undefined}
            >
              <img src={it.url} alt={it.label ?? ""} />
              {it.label && <div className="hist-meta">{it.label}</div>}
              {activeId === it.id && <span className="thumb-check" aria-hidden>✓</span>}
            </button>
          ))}
        </div>
      </div>

      <Tooltip label="Next">
        <button className="filmstrip-arrow right" onClick={() => embla?.scrollNext()} disabled={!canNext}>›</button>
      </Tooltip>
    </div>
  );
}


