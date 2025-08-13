import { Link } from "react-router-dom";
import type { BedLatest } from "../types/types";
import { supabase } from "../lib/supabaseClient";

export default function BedCard({ bed, sectionSlug }: { bed: BedLatest; sectionSlug: string }) {
  const url = bed.image_path
    ? supabase.storage.from("plant-images").getPublicUrl(bed.image_path).data.publicUrl
    : "";

  const isActive = (bed.pin_count || 0) > 0;

  return (
    <Link to={`/section/${sectionSlug}/bed/${bed.id}`} className="bed-card">
      <div className="thumb">
        {url ? (
          <img src={url} alt={bed.name} />
        ) : (
          <div className="thumb-empty">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M12 5v14M5 12h14"/>
            </svg>
            <span>No image</span>
          </div>
        )}
        
        {/* Status indicator */}
        <div className={`bed-status-indicator ${isActive ? '' : 'inactive'}`}></div>
        
        {/* Plant count badge */}
        {isActive && (
          <div className="plant-count-badge">
            {bed.pin_count} plant{bed.pin_count !== 1 ? 's' : ''}
          </div>
        )}
      </div>
      
      <div className="meta">
        <div className="name">{bed.name}</div>
        <div className="sub">
          {isActive ? (
            <span className="bed-status active">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M9 12l2 2 4-4"/>
              </svg>
              Active
            </span>
          ) : (
            <span className="bed-status inactive">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M8 12l8 8M16 12l-8 8"/>
              </svg>
              Empty
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}