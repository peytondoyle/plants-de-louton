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

  const human = (slug ?? "").replace(/-/g, " ");
  const title = human ? human[0].toUpperCase() + human.slice(1) : human;

  const totalPlants = beds.reduce((sum, bed) => sum + (bed.pin_count || 0), 0);

  return (
    <div className="app-root container">
      {/* Hero Section */}
      <section className="section-hero">
        <div className="section-hero-content">
          <div className="section-hero-text">
            <h1 className="section-hero-title">{title}</h1>
            <p className="section-hero-subtitle">
              Manage your garden beds and plant collections in this section
            </p>
            {!loading && (
              <div className="section-stats">
                <span className="section-stat">
                  <strong>{beds.length}</strong> bed{beds.length !== 1 ? 's' : ''}
                </span>
                <span className="section-stat">
                  <strong>{totalPlants}</strong> plant{totalPlants !== 1 ? 's' : ''}
                </span>
              </div>
            )}
          </div>
          <div className="section-hero-actions">
            <button 
              className="ui-btn ui-btn--primary ui-btn--lg"
              onClick={() => setShowNew(true)}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M12 5v14M5 12h14"/>
              </svg>
              Add New Bed
            </button>
          </div>
        </div>
      </section>

      {/* Beds Grid */}
      <section className="section-content">
        <div className="content-header">
          <h2 className="content-title">Garden Beds</h2>
          <div className="content-meta">
            <Link to="/" className="ui-btn ui-btn--sm ui-btn--ghost">All sections</Link>
            {loading ? (
              <span className="loading-text">Loading beds...</span>
            ) : (
              <span className="bed-count">{beds.length} bed{beds.length !== 1 ? 's' : ''}</span>
            )}
          </div>
        </div>

        {loading ? (
          <div className="loading-state">
            <div className="spinner spinner--lg"></div>
            <p>Loading your garden beds...</p>
          </div>
        ) : beds.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M12 5v14M5 12h14"/>
              </svg>
            </div>
            <h3 className="empty-state-title">No beds yet</h3>
            <p className="empty-state-description">
              Create your first garden bed to start tracking your plants
            </p>
            <button 
              className="ui-btn ui-btn--primary"
              onClick={() => setShowNew(true)}
            >
              Create Your First Bed
            </button>
          </div>
        ) : (
          <div className="beds-grid">
            {beds.map((b) => <BedCard key={b.id} bed={b} sectionSlug={slug} />)}
          </div>
        )}
      </section>

      {/* Floating Action Button */}
      <button 
        className="fab"
        onClick={() => setShowNew(true)}
        aria-label="Add new bed"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M12 5v14M5 12h14"/>
        </svg>
      </button>

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