import React, { useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin } from "../types/types";

type Props = {
  bedId: string;
  imageUrl: string;
  /** Only show pins that belong to this bed image. If omitted, shows all pins for the bed. */
  imageId?: string;
  section?: string;
  bedName?: string;

  // external editor hooks
  onCreateAt?: (pos: { x: number; y: number }) => void;
  onEditPin?: (pin: Pin) => void;
  onPinsChange?: (pins: Pin[]) => void;

  /** We use the drawer editor in BedDetail, so keep this true by default. */
  useExternalEditor?: boolean;

  /** When true, renders the inline hint above the image. */
  showInlineHint?: boolean;
};

export default function PinDropper({
  bedId,
  imageUrl,
  imageId,
  section,
  bedName,
  onCreateAt,
  onEditPin,
  onPinsChange,
  useExternalEditor = true,
  showInlineHint = false,
}: Props) {
  const [pins, setPins] = useState<Pin[]>([]);
  const [loading, setLoading] = useState(true);
  const imgRef = useRef<HTMLImageElement | null>(null);

  // Load pins for this bed (+ optional image filter)
  useEffect(() => {
    let cancel = false;

    async function run() {
      setLoading(true);

      let query = supabase
        .from("pins")
        .select("*")
        .eq("bed_id", bedId);

      if (imageId) query = query.eq("image_id", imageId);

      const { data, error } = await query.order("created_at", { ascending: true });

      if (!cancel) {
        if (error) {
          alert(error.message);
          setPins([]);
        } else {
          const list = (data ?? []) as Pin[];
          setPins(list);
          onPinsChange?.(list);
        }
        setLoading(false);
      }
    }

    void run();
    return () => {
      cancel = true;
    };
  }, [bedId, imageId, onPinsChange]);

  const canInteract = useMemo(
    () => Boolean(imageUrl && bedId),
    [imageUrl, bedId]
  );

  const handleImageClick = (e: React.MouseEvent) => {
    if (!canInteract || !imgRef.current) return;
    const rect = imgRef.current.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const y = (e.clientY - rect.top) / rect.height;
    onCreateAt?.({ x: clamp01(x), y: clamp01(y) });
  };

  const editPin = (pin: Pin) => onEditPin?.(pin);

  const pinEls = useMemo(
    () =>
      pins.map((p) => (
        <button
          key={p.id}
          className="pin"
          title={p.name ?? undefined}          // ← fix: null -> undefined

          style={{ left: `${p.x * 100}%`, top: `${p.y * 100}%` }}
          onClick={(e) => {
            e.stopPropagation();
            editPin(p);
          }}
          aria-label={p.name || "pin"}
        />
      )),
    [pins]
  );

  return (
    <div className="pinboard-wrap">
      {showInlineHint && (
        <p className="hint">Click the image to drop a pin. Click a pin to edit or delete.</p>
      )}

      <div
        className={`pinboard ${imageUrl ? "ready" : "empty"}`}
        onClick={imageUrl ? handleImageClick : undefined}
      >
        {!imageUrl ? (
          <div className="empty-state">
            <p>Upload an image to begin pinning.</p>
          </div>
        ) : (
          <div className="pinboard-stage">
            <div className="image-shell">
              <img
                ref={imgRef}
                src={imageUrl}
                alt={`${section ?? ""} — ${bedName ?? ""}`}
                loading="eager"
                decoding="async"
                draggable={false}
              />
              <div className="pins-layer">{pinEls}</div>
            </div>
          </div>
        )}
      </div>

      {loading && (
        <div className="modal-backdrop">
          <div className="modal"><p>Loading…</p></div>
        </div>
      )}
    </div>
  );
}

function clamp01(n: number) {
  return Math.max(0, Math.min(1, n));
}