import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { supabase } from "../lib/supabaseClient";
import type { BedImage } from "../types/types";

type Props = {
  images: BedImage[];
  activePath?: string | null;
  onSelect: (img: BedImage, url: string) => void;
};

export default function SidebarImageHistory({ images, activePath = null, onSelect }: Props) {
  const scrollerRef = useRef<HTMLDivElement | null>(null);
  const [canLeft, setCanLeft] = useState(false);
  const [canRight, setCanRight] = useState(false);

  const items = useMemo(() => {
    return images.map((img) => {
      const { data } = supabase.storage.from("plant-images").getPublicUrl(img.image_path);
      return {
        img,
        url: data.publicUrl,
        ts: img.created_at ? new Date(img.created_at) : null,
      };
    });
  }, [images]);

  if (!items.length) return null;

  const scrollByDir = (dir: number) => {
    const el = scrollerRef.current; if (!el) return;
    const first = el.querySelector<HTMLElement>(".hist-thumb");
    if (!first) return;
    const step = first.offsetWidth + 10; // thumb width + gap
    const left = el.scrollLeft || 0;
    const maxLeft = Math.max(0, el.scrollWidth - el.clientWidth);
    const currentIndex = Math.round(left / step);
    const nextIndex = Math.max(0, Math.min(Math.ceil((el.scrollWidth - 1) / step) - 1, currentIndex + dir));
    const target = Math.max(0, Math.min(maxLeft, nextIndex * step));
    el.scrollTo({ left: target, behavior: "smooth" });
  };

  // Update arrow enabled/disabled state
  useEffect(() => {
    const el = scrollerRef.current; if (!el) return;
    const update = () => {
      // guard against NaN or transient zero widths
      const left = el.scrollLeft || 0;
      const cw = el.clientWidth || 0;
      const sw = el.scrollWidth || 0;
      setCanLeft(left > 2);
      setCanRight(left + cw < sw - 2);
    };
    update();
    el.addEventListener('scroll', update, { passive: true });
    const ro = new ResizeObserver(update);
    ro.observe(el);
    window.addEventListener('resize', update);
    return () => {
      el.removeEventListener('scroll', update as any);
      ro.disconnect();
      window.removeEventListener('resize', update);
    };
  }, [images.length]);

  return (
    <div className="filmstrip-wrap">
      <button type="button" className="filmstrip-arrow left" aria-label="Scroll left" onClick={() => scrollByDir(-1)} disabled={!canLeft}>‹</button>
      <div ref={scrollerRef} className="image-history sidebar-filmstrip" role="list" aria-label="Image history">
      {items.map(({ img, url, ts }) => {
        const active = img.image_path === activePath;
        const title = ts
          ? ts.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })
          : img.image_path;
        const ratio = img.width && img.height ? `${img.width} / ${img.height}` : undefined;

        return (
          <button
            key={img.id}
            type="button"
            role="listitem"
            className={`hist-thumb ${active ? "active" : ""}`}
            title={title}
            aria-current={active ? "true" : undefined}
            aria-pressed={active ? true : undefined}
            onClick={() => onSelect(img, url)}
            style={ratio ? ({ aspectRatio: ratio } as CSSProperties) : undefined}
          >
            <img src={url} alt="" loading="lazy" decoding="async" draggable={false} />
            {ts && <div className="hist-meta">{ts.toLocaleDateString()}</div>}
            {active && <span className="thumb-check" aria-hidden="true">✓</span>}
          </button>
        );
      })}
      </div>
      <button type="button" className="filmstrip-arrow right" aria-label="Scroll right" onClick={() => scrollByDir(1)} disabled={!canRight}>›</button>
    </div>
  );
}


