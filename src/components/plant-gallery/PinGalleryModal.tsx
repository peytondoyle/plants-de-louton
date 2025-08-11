import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { deletePinMedia, getPinMedia, uploadPinMedia } from "../../lib/pinMedia";
import type { Pin } from "../../types/types";
import "./PlantGalleryModal.css";

export default function PinGalleryModal({ pinId, imageId, onClose }: { pinId: string; imageId?: string; onClose: () => void }) {
  const [items, setItems] = useState<{ id: string; url: string }[]>([]);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const portal = document.body;

  useEffect(() => {
    let cancel = false;
    (async () => {
      const media = await getPinMedia(pinId);
      if (!cancel) setItems(media);
    })();
    return () => { cancel = true; };
  }, [pinId]);

  const upload = async (f: File) => {
    setBusy(true);
    try {
      await uploadPinMedia(pinId, f, { imageId });
      const media = await getPinMedia(pinId);
      setItems(media);
      setStatus({ type: 'success', message: 'Uploaded' });
      setTimeout(() => setStatus(null), 1500);
    } finally { setBusy(false); }
  };

  const remove = async (id: string) => {
    if (!confirm("Delete this photo?")) return;
    await deletePinMedia(id);
    setItems((prev) => prev.filter((m) => m.id !== id));
  };

  return createPortal(
    <div className="pgm-backdrop" onClick={onClose}>
      <div className="pgm" onClick={(e) => e.stopPropagation()}>
        <div className="pgm-head">
          <div className="pgm-title">Pin photos</div>
          <div className="pgm-actions">
            <button className="ui-btn ui-btn--sm" onClick={() => inputRef.current?.click()} disabled={busy}>Upload</button>
            <button className="ui-btn ui-btn--sm ui-btn--ghost" onClick={onClose}>Close</button>
            {busy ? (<div className="pgm-status"><span className="pgm-spinner" aria-hidden />Uploading…</div>) : status ? (<div className="pgm-status" role="status" aria-live="polite">{status.message}</div>) : null}
          </div>
        </div>
        <div className="pgm-grid">
          {items.map((m) => (
            <div key={m.id} className="pgm-item">
              <img src={m.url} alt="Pin media" loading="lazy" />
              <div className="pgm-row">
                <span />
                <button className="ui-btn ui-btn--sm ui-btn--ghost" onClick={() => remove(m.id)}>Delete</button>
              </div>
            </div>
          ))}
        </div>
        <input
          ref={inputRef}
          type="file"
          accept="image/*"
          style={{ display: "none" }}
          onChange={(e) => { const f = e.target.files?.[0]; if (f) upload(f); e.currentTarget.value = ""; }}
        />
      </div>
    </div>,
    portal
  );
}



