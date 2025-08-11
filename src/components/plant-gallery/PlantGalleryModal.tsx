import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { deletePlantMedia, getPlantMedia, uploadPlantMedia } from "../../lib/plantMedia";
import type { PlantMedia } from "../../types/types";
import "./PlantGalleryModal.css";

type Props = {
  plantId: string;
  onClose: () => void;
  initialFocusId?: string;
  linkBack?: { imageId?: string; pinId?: string };
  onViewOnMap?: (args: { imageId?: string; pinId?: string }) => void;
};

export default function PlantGalleryModal({ plantId, onClose, initialFocusId, linkBack, onViewOnMap }: Props) {
  const [items, setItems] = useState<PlantMedia[]>([]);
  const [busy, setBusy] = useState(false);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const portal = document.body;

  useEffect(() => {
    let cancel = false;
    (async () => {
      const media = await getPlantMedia(plantId);
      if (!cancel) setItems(media);
    })();
    return () => { cancel = true; };
  }, [plantId]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  const upload = async (f: File) => {
    setBusy(true);
    try {
      await uploadPlantMedia(plantId, f, { imageId: linkBack?.imageId, pinId: linkBack?.pinId });
      const media = await getPlantMedia(plantId);
      setItems(media);
    } finally { setBusy(false); }
  };

  const remove = async (id: string) => {
    if (!confirm("Delete this photo?")) return;
    await deletePlantMedia(id);
    setItems((prev) => prev.filter((m) => m.id !== id));
  };

  return createPortal(
    <div className="pgm-backdrop" onClick={onClose}>
      <div className="pgm" onClick={(e) => e.stopPropagation()}>
        <div className="pgm-head">
          <div className="pgm-title">Plant photos</div>
          <div className="pgm-actions">
            <button className="ui-btn ui-btn--sm" onClick={() => inputRef.current?.click()} disabled={busy}>Upload</button>
            <button className="ui-btn ui-btn--sm ui-btn--ghost" onClick={onClose}>Close</button>
          </div>
        </div>
        <div className="pgm-grid">
          {items.map((m) => (
            <div key={m.id} className="pgm-item">
              {/* eslint-disable-next-line jsx-a11y/alt-text */}
              <img src={m.url} loading="lazy" />
              <div className="pgm-row">
                {m.image_id || m.pin_id ? (
                  <button className="ui-btn ui-btn--sm" onClick={() => onViewOnMap?.({ imageId: m.image_id ?? undefined, pinId: m.pin_id ?? undefined })}>View on map</button>
                ) : <span />}
                <button className="ui-btn ui-btn--sm ui-btn--ghost" onClick={() => remove(m.id)}>Delete</button>
              </div>
            </div>
          ))}
        </div>
        <input ref={inputRef} type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => e.target.files?.[0] && upload(e.target.files[0])} />
      </div>
    </div>,
    portal
  );
}


