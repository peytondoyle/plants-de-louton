import { Link } from "react-router-dom";
import type { BedLatest } from "../types/types";
import { supabase } from "../lib/supabaseClient";

export default function BedCard({ bed, sectionSlug }: { bed: BedLatest; sectionSlug: string }) {
  const url = bed.image_path
    ? supabase.storage.from("plant-images").getPublicUrl(bed.image_path).data.publicUrl
    : "";

  return (
    <Link to={`/section/${sectionSlug}/bed/${bed.id}`} className="bed-card">
      <div className="thumb">
        {url ? (
          <img src={url} alt={bed.name} />
        ) : (
          <div className="thumb-empty">No image</div>
        )}
      </div>
      <div className="meta">
        <div className="name">{bed.name}</div>
        <div className="sub">{bed.pin_count} {bed.pin_count === 1 ? "pin" : "pins"}</div>
      </div>
    </Link>
  );
}