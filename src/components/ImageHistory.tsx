import { supabase } from "../lib/supabaseClient";
import type { BedImage } from "../types/types";

export default function ImageHistory({
  images,
  activePath,
  onSelect,
}: {
  images: BedImage[];
  activePath?: string | null;
  onSelect: (img: BedImage, url: string) => void;
}) {
  return (
    <div className="image-history">
      {images.map((img) => {
        const url = supabase.storage.from("plant-images").getPublicUrl(img.image_path).data.publicUrl;
        const active = img.image_path === activePath;
        return (
          <button key={img.id} className={`hist-thumb ${active ? "active" : ""}`} onClick={() => onSelect(img, url)}>
            <img src={url} alt="" />
          </button>
        );
      })}
    </div>
  );
}