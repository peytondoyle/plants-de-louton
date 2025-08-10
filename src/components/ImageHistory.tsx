import { useMemo } from "react";
import { supabase } from "../lib/supabaseClient";
import type { BedImage } from "../types/types";

type Props = {
  images: BedImage[];
  activePath?: string | null;
  onSelect: (img: BedImage, url: string) => void;
};

export default function ImageHistory({ images, activePath = null, onSelect }: Props) {
  // Precompute public URLs once per images array
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

  return (
    <div className="image-history" role="list" aria-label="Image history">
      {items.map(({ img, url, ts }) => {
        const active = img.image_path === activePath;
        const title = ts
          ? ts.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })
          : img.image_path;

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
          >
            <img
              src={url}
              alt=""
              loading="lazy"
              decoding="async"
              draggable={false}
            />
            {/* Tiny date stripe overlay */}
            {ts && (
              <div className="hist-meta">
                {ts.toLocaleDateString()}
              </div>
            )}
            {active && <span className="thumb-check" aria-hidden="true">✓</span>}
          </button>
        );
      })}
    </div>
  );
}