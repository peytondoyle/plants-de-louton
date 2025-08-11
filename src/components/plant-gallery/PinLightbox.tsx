import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { getPinMedia } from "../../lib/pinMedia";

type Props = { pinId: string; onClose: () => void; startIndex?: number };

type Item = {
  id: string;
  url: string;
  created_at?: string;
};

export default function PinLightbox({ pinId, onClose, startIndex = 0 }: Props) {
  const [items, setItems] = useState<Item[]>([]);
  const [idx, setIdx] = useState(startIndex);
  const [chromeVisible, setChromeVisible] = useState(true);
  const hideRef = useRef<number | null>(null);
  const [hoverClose, setHoverClose] = useState(false);

  useEffect(() => {
    let cancel = false;
    (async () => {
      const media = await getPinMedia(pinId);
      if (!cancel) setItems(media.map(m => ({ id: m.id, url: m.url, created_at: m.created_at })));
    })();
    return () => { cancel = true; };
  }, [pinId]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowRight') setIdx(i => Math.min(i + 1, Math.max(0, items.length - 1)));
      if (e.key === 'ArrowLeft') setIdx(i => Math.max(i - 1, 0));
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [items.length, onClose]);

  // Auto-hide top/bottom chrome; show on interaction
  useEffect(() => {
    const show = () => {
      setChromeVisible(true);
      if (hideRef.current) cancelAnimationFrame(hideRef.current);
      const start = performance.now();
      const step = () => {
        if (performance.now() - start > 1800) {
          setChromeVisible(false);
        } else {
          hideRef.current = requestAnimationFrame(step);
        }
      };
      hideRef.current = requestAnimationFrame(step);
    };
    show();
    const onMove = () => show();
    document.addEventListener('mousemove', onMove);
    document.addEventListener('touchstart', onMove, { passive: true });
    return () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('touchstart', onMove);
      if (hideRef.current) cancelAnimationFrame(hideRef.current);
    };
  }, []);

  if (items.length === 0) return null;
  const cur = items[Math.min(idx, items.length - 1)];
  const ts = cur.created_at
    ? new Date(cur.created_at).toLocaleDateString(undefined, {
        year: 'numeric', month: 'short', day: 'numeric'
      })
    : '';

  return createPortal(
    <div
      onClick={onClose}
      style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.9)', zIndex: 4000, display: 'grid', placeItems: 'center' }}
    >
      <div onClick={(e) => e.stopPropagation()} style={{ position: 'relative', padding: 20 }}>
        {/* image + overlay chrome inside the image bounds */}
        <div style={{ position: 'relative', display: 'inline-block' }}>
          <img src={cur.url} style={{ maxWidth: 'calc(100vw - 80px)', maxHeight: 'calc(100vh - 80px)', objectFit: 'contain', display: 'block' }} />
          {ts ? (
            <div
              style={{
                position: 'absolute',
                left: 12,
                bottom: 12,
                background: 'rgba(17,24,39,0.8)',
                color: '#fff',
                padding: '6px 10px',
                borderRadius: 999,
                fontSize: 12,
                boxShadow: '0 4px 16px rgba(0,0,0,0.35)',
                opacity: chromeVisible ? 1 : 0,
                transition: 'opacity .25s ease'
              }}
            >
              {ts}
            </div>
          ) : null}
        </div>
        {/* nav */}
        {idx > 0 ? (
          <button
            onClick={(e) => { e.stopPropagation(); setIdx(i => Math.max(i - 1, 0)); }}
            style={{ position: 'fixed', left: 16, top: '50%', transform: 'translateY(-50%)', background: 'rgba(255,255,255,0.18)', color: '#fff', border: 0, borderRadius: 999, width: 36, height: 36, cursor: 'pointer', opacity: chromeVisible ? 1 : 0, transition: 'opacity .25s ease' }}
            aria-label="Previous"
          >
            ‹
          </button>
        ) : null}
        {idx < items.length - 1 ? (
          <button
            onClick={(e) => { e.stopPropagation(); setIdx(i => Math.min(i + 1, items.length - 1)); }}
            style={{ position: 'fixed', right: 16, top: '50%', transform: 'translateY(-50%)', background: 'rgba(255,255,255,0.18)', color: '#fff', border: 0, borderRadius: 999, width: 36, height: 36, cursor: 'pointer', opacity: chromeVisible ? 1 : 0, transition: 'opacity .25s ease' }}
            aria-label="Next"
          >
            ›
          </button>
        ) : null}
        {/* Close by clicking backdrop; explicit button removed for a cleaner look */}
      </div>
    </div>,
    document.body
  );
}


