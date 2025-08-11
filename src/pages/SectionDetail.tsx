// src/pages/SectionDetail.tsx
import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import NewBedModal from "../components/NewBedModal";
import { getPinsBySection } from "../lib/getPinsBySection";
import { listBedsBySection } from "../lib/listBedsBySection";
import type { PlantPin, BedLatest, Bed, BedImage } from "../types/types";

export default function SectionDetail() {
  const { slug } = useParams();
  const section = slug ?? "";

  // legacy list (plant_pins)
  const [legacyPins, setLegacyPins] = useState<PlantPin[]>([]);
  const [legacyLoading, setLegacyLoading] = useState(true);

  // new beds system
  const [beds, setBeds] = useState<BedLatest[]>([]);
  const [bedsLoading, setBedsLoading] = useState(true);
  const [showNewBedModal, setShowNewBedModal] = useState(false);

  useEffect(() => {
    if (!section) return;
    
    const loadData = async () => {
      setLegacyLoading(true);
      setBedsLoading(true);
      
      try {
        const [legacyData, bedsData] = await Promise.all([
          getPinsBySection(section),
          listBedsBySection(section)
        ]);
        
        setLegacyPins(legacyData);
        setBeds(bedsData);
      } catch (error) {
        console.error('Error loading section data:', error);
      } finally {
        setLegacyLoading(false);
        setBedsLoading(false);
      }
    };

    loadData();
  }, [section]);

  const human = (section ?? "").replace(/-/g, " ");
  const title = human ? human[0].toUpperCase() + human.slice(1) : human;

  const handleBedCreated = ({ bed, image, publicUrl }: { bed: Bed; image: BedImage; publicUrl: string }) => {
    // Refresh beds list
    listBedsBySection(section).then(setBeds);
  };

  return (
    <div className="app-root container">
      {/* Hero Section */}
      <div className="section-hero">
        <div className="section-hero-content">
          <div className="section-hero-text">
            <h1 className="section-hero-title">{title}</h1>
            <p className="section-hero-subtitle">
              Manage your garden beds and plant collections in this section
            </p>
          </div>
          <div className="section-hero-actions">
            <button 
              className="ui-btn ui-btn--primary ui-btn--lg"
              onClick={() => setShowNewBedModal(true)}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M12 5v14M5 12h14"/>
              </svg>
              Create New Bed
            </button>
          </div>
        </div>
      </div>

      {/* Beds Grid */}
      <div className="section-content">
        <div className="content-header">
          <h2 className="content-title">Garden Beds</h2>
          <div className="content-meta">
            {bedsLoading ? (
              <span className="loading-text">Loading beds...</span>
            ) : (
              <span className="bed-count">{beds.length} bed{beds.length !== 1 ? 's' : ''}</span>
            )}
          </div>
        </div>

        {bedsLoading ? (
          <div className="loading-state">
            <div className="spinner spinner--lg"></div>
            <p>Loading your garden beds...</p>
          </div>
        ) : beds.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1">
                <path d="M21 19V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2z"/>
                <path d="M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/>
                <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>
              </svg>
            </div>
            <h3 className="empty-state-title">No beds yet</h3>
            <p className="empty-state-text">
              Create your first garden bed to start organizing your plants
            </p>
            <button 
              className="ui-btn ui-btn--primary"
              onClick={() => setShowNewBedModal(true)}
            >
              Create Your First Bed
            </button>
          </div>
        ) : (
          <div className="beds-grid">
            {beds.map((bed) => (
              <Link 
                key={bed.id} 
                to={`/bed/${bed.id}`}
                className="bed-card bed-card--modern"
              >
                <div className="bed-card-image">
                  {bed.image_path ? (
                    <img 
                      src={`https://your-supabase-project.supabase.co/storage/v1/object/public/plant-images/${bed.image_path}`}
                      alt={bed.name}
                      className="bed-image"
                    />
                  ) : (
                    <div className="bed-image-placeholder">
                      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1">
                        <path d="M21 19V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2z"/>
                        <path d="M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/>
                        <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>
                      </svg>
                    </div>
                  )}
                  {bed.pin_count > 0 && (
                    <div className="bed-pin-badge">
                      <span>{bed.pin_count}</span>
                    </div>
                  )}
                </div>
                <div className="bed-card-content">
                  <h3 className="bed-card-title">{bed.name}</h3>
                  <div className="bed-card-meta">
                    <span className="bed-created">
                      Created {new Date(bed.created_at).toLocaleDateString()}
                    </span>
                    {bed.pin_count > 0 && (
                      <span className="bed-pins">
                        {bed.pin_count} plant{bed.pin_count !== 1 ? 's' : ''}
                      </span>
                    )}
                  </div>
                </div>
                <div className="bed-card-arrow">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M9 18l6-6-6-6"/>
                  </svg>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      {/* Legacy Pins Section */}
      {legacyPins.length > 0 && (
        <div className="section-content">
          <div className="content-header">
            <h2 className="content-title">Legacy Plant Pins</h2>
            <div className="content-meta">
              <span className="legacy-note">From previous system</span>
            </div>
          </div>
          
          <div className="legacy-pins-grid">
            {legacyPins.map((pin) => (
              <div key={pin.id} className="legacy-pin-card">
                {pin.image_url && (
                  <div className="legacy-pin-image">
                    <img
                      src={pin.image_url}
                      alt={pin.plant_name}
                      className="legacy-pin-img"
                    />
                  </div>
                )}
                <div className="legacy-pin-content">
                  <h4 className="legacy-pin-name">{pin.plant_name}</h4>
                  {pin.detailed_name && (
                    <p className="legacy-pin-details">{pin.detailed_name}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* New Bed Modal */}
      {showNewBedModal && (
        <NewBedModal
          section={section}
          onClose={() => setShowNewBedModal(false)}
          onCreated={handleBedCreated}
        />
      )}
    </div>
  );
}