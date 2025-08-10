import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { listBedsBySection } from "../lib/listBedsBySection";
import BedCard from "../components/BedCard";
import NewBedModal from "../components/NewBedModal";
import type { Bed, BedLatest } from "../types/types";

export default function SectionIndex() {
  const { slug = "" } = useParams();
  const [beds, setBeds] = useState<BedLatest[]>([]);
  const [loading, setLoading] = useState(true);
  const [showNew, setShowNew] = useState(false);

  useEffect(() => {
    let cancel = false;
    (async () => {
      setLoading(true);
      try { const data = await listBedsBySection(slug); if (!cancel) setBeds(data); }
      finally { if (!cancel) setLoading(false); }
    })();
    return () => { cancel = true; };
  }, [slug]);

  return (
    <div className="app-root container">
      <div className="page-toolbar" style={{ justifyContent: "space-between" }}>
        <h1 className="page-title capitalize" style={{ margin: 0 }}>{slug.replace("-", " ")}</h1>
        <div className="flex gap-2">
          <Link to="/" className="ui-btn ui-btn--sm ui-btn--ghost">All sections</Link>
          <button className="ui-btn ui-btn--sm" onClick={() => setShowNew(true)}>Add bed</button>
        </div>
      </div>

      {loading ? (
        <p>Loading…</p>
      ) : beds.length === 0 ? (
        <div className="text-gray-500">No beds yet. <button className="underline" onClick={() => setShowNew(true)}>Create one</button>.</div>
      ) : (
        <div className="beds-grid">
          {beds.map((b) => <BedCard key={b.id} bed={b} sectionSlug={slug} />)}
        </div>
      )}

      {showNew && (
        <NewBedModal
          section={slug}
          onClose={() => setShowNew(false)}
          onCreated={({ bed }) => (window.location.href = `/section/${slug}/bed/${bed.id}`)}
        />
      )}
    </div>
  );
}