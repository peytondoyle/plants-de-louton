import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin, PlantDetails, PlantInstance, CareEvent } from "../types/types";
import { uploadPinMedia, getPinMedia } from "../lib/pinMedia";
import { createPlantDetails, updatePlantDetails, getPlantDetails } from "../lib/plantDetails";
import { createPlantInstance, updatePlantInstance, getPlantInstanceByPinId } from "../lib/plantInstances";
import { createCareEvent, updateCareEvent, deleteCareEvent, listCareEventsByPlantInstance } from "../lib/careEvents";
import { searchPlants, type AIPlantSearchResult } from "../lib/aiPlantSearch";

type EditorTab = 'basic' | 'plant_details' | 'care_history' | 'photos' | 'notes';

type Draft =
  | (Pin & { isEdit?: true })
  | ({ 
      id?: undefined; 
      bed_id: string; 
      image_id: string | null; 
      x: number; 
      y: number; 
      name?: string; 
      notes?: string; 
      status?: 'active' | 'dormant' | 'removed' | 'dead';
    });

// Type guard functions
function isPin(draft: Draft | { x: number; y: number } | null): draft is Pin {
  return draft !== null && 'id' in draft && draft.id !== undefined;
}

function isNewPin(draft: Draft | { x: number; y: number } | null): draft is { bed_id: string; image_id: string | null; x: number; y: number; name?: string; notes?: string; status?: 'active' | 'dormant' | 'removed' | 'dead'; } {
  return draft !== null && (!('id' in draft) || draft.id === undefined);
}

type Props = {
  open: boolean;
  onClose: () => void;

  bedId: string;
  /** Associate new pins with a specific bed image (or null if "unscoped"). */
  imageId?: string;

  /** Existing pin to edit OR a position to create at. */
  initial?: Pin | { x: number; y: number };

  onSaved: (pin: Pin) => void;
  onDeleted: (id: string) => void;
  onOpenPinGallery?: (args: { pinId: string }) => void;
};

export default function PinEditorDrawer({
  open,
  onClose,
  bedId,
  imageId,
  initial,
  onSaved,
  onDeleted,
  onOpenPinGallery,
}: Props) {
  
  const [draft, setDraft] = useState<Draft | null>(null);
  const [activeTab, setActiveTab] = useState<EditorTab>('basic');
  const [featuredUrl, setFeaturedUrl] = useState<string | null>(null);
  const [uploadingFeatured, setUploadingFeatured] = useState(false);
  const featuredInputRef = useRef<HTMLInputElement>(null);
  
  // Plant data state
  const [plantDetails, setPlantDetails] = useState<PlantDetails | null>(null);
  const [plantInstance, setPlantInstance] = useState<PlantInstance | null>(null);
  const [loadingPlantData, setLoadingPlantData] = useState(false);
  const [careEvents, setCareEvents] = useState<CareEvent[]>([]);
  const [loadingCareEvents, setLoadingCareEvents] = useState(false);

  // Load plant data when drawer opens
  useEffect(() => {
    if (open && draft && isPin(draft)) {
      loadPlantData(draft.id);
    } else {
      setPlantDetails(null);
      setPlantInstance(null);
    }
  }, [open, draft]);

  const loadPlantData = async (pinId: string) => {
    setLoadingPlantData(true);
    setLoadingCareEvents(true);
    try {
      // Load plant instance (which includes plant details)
      const instance = await getPlantInstanceByPinId(pinId);
      if (instance) {
        setPlantInstance(instance);
        setPlantDetails(instance.plant_details as PlantDetails);
        
        // Load care events for this plant instance
        const events = await listCareEventsByPlantInstance(instance.id);
        setCareEvents(events);
      } else {
        setPlantInstance(null);
        setPlantDetails(null);
        setCareEvents([]);
      }
    } catch (error) {
      console.error('Error loading plant data:', error);
      setPlantInstance(null);
      setPlantDetails(null);
      setCareEvents([]);
    } finally {
      setLoadingPlantData(false);
      setLoadingCareEvents(false);
    }
  };

  // Prime the draft whenever the drawer opens
  useEffect(() => {
    if (!open) return;
    if (!initial) {
      setDraft(null);
      return;
    }

    if (isPin(initial)) {
      setDraft({ ...initial, isEdit: true });
      // For existing pins, stay on basic tab
      setActiveTab('basic');
    } else {
      setDraft({
        bed_id: bedId,
        image_id: imageId ?? null,
        x: initial.x,
        y: initial.y,
        name: "",
        notes: "",
        status: 'active',
      });
      // For new pins, start on AI search tab
      setActiveTab('plant_details');
    }
  }, [open, initial, bedId, imageId]);

  // Load a small featured preview from pin_media (first photo)
  useEffect(() => {
    let cancel = false;
    (async () => {
      if (!open || !draft || !isPin(draft)) return;
      try {
        const media = await getPinMedia(draft.id);
        if (!cancel) setFeaturedUrl(media[0]?.url ?? null);
      } catch {
        if (!cancel) setFeaturedUrl(null);
      }
    })();
    return () => { cancel = true; };
  }, [open, draft]);

  const baseline = useMemo(() => {
    if (!initial || !isPin(initial)) return null;
    const p = initial;
    return { name: p.name ?? "", notes: p.notes ?? "" };
  }, [initial]);

  const isDirty = useMemo(() => {
    if (!draft) return false;
    if (!isPin(draft)) return true; // new pin being created elsewhere
    if (!baseline) return false;
    return (draft.name ?? "") !== baseline.name || (draft.notes ?? "") !== baseline.notes;
  }, [draft, baseline]);

  const handleSave = async () => {
    if (!draft) return;
    
    try {
      let savedPin: Pin;
      
      if (isPin(draft)) {
        // Update existing pin
        const { data, error } = await supabase
          .from("pins")
          .update({
            name: draft.name,
            notes: draft.notes,
            x: draft.x,
            y: draft.y,
            status: draft.status,
            last_care_date: draft.last_care_date,
            next_care_date: draft.next_care_date,
          })
          .eq("id", draft.id)
          .select("*")
          .single();
        if (error) throw error;
        savedPin = data as Pin;
      } else {
        // Create new pin
        const { data, error } = await supabase
          .from("pins")
          .insert({
            bed_id: bedId,
            image_id: imageId,
            name: draft.name,
            notes: draft.notes,
            x: draft.x,
            y: draft.y,
            status: draft.status || 'active',
          })
          .select("*")
          .single();
        if (error) throw error;
        savedPin = data as Pin;
      }
      
      // Handle plant details and instance if we have them
      if (plantDetails && savedPin) {
        let detailsId = plantDetails.id;
        
        // Create or update plant details
        if (!plantDetails.id) {
          // New plant details
          const newDetails = await createPlantDetails({
            name: plantDetails.name,
            scientific_name: plantDetails.scientific_name,
            common_names: plantDetails.common_names,
            family: plantDetails.family,
            genus: plantDetails.genus,
            species: plantDetails.species,
            cultivar: plantDetails.cultivar,
            growth_habit: plantDetails.growth_habit,
            hardiness_zones: plantDetails.hardiness_zones,
            sun_exposure: plantDetails.sun_exposure,
            water_needs: plantDetails.water_needs,
            mature_height: plantDetails.mature_height,
            mature_width: plantDetails.mature_width,
            bloom_time: plantDetails.bloom_time,
            bloom_duration: plantDetails.bloom_duration,
            flower_color: plantDetails.flower_color,
            foliage_color: plantDetails.foliage_color,
            soil_type: plantDetails.soil_type,
            soil_ph: plantDetails.soil_ph,
            fertilizer_needs: plantDetails.fertilizer_needs,
            pruning_needs: plantDetails.pruning_needs,
            planting_season: plantDetails.planting_season,
            planting_depth: plantDetails.planting_depth,
            spacing: plantDetails.spacing,
          });
          detailsId = newDetails.id;
        } else {
          // Update existing plant details
          await updatePlantDetails(plantDetails.id, plantDetails);
        }
        
        // Create or update plant instance
        if (plantInstance) {
          if (!plantInstance.id) {
            // New plant instance
            await createPlantInstance({
              plant_details_id: detailsId,
              bed_id: bedId,
              pin_id: savedPin.id,
              planted_date: plantInstance.planted_date,
              source: plantInstance.source,
              source_notes: plantInstance.source_notes,
              cost: plantInstance.cost,
              health_status: plantInstance.health_status,
              notes: plantInstance.notes,
            });
          } else {
            // Update existing plant instance
            await updatePlantInstance(plantInstance.id, {
              plant_details_id: detailsId,
              planted_date: plantInstance.planted_date,
              source: plantInstance.source,
              source_notes: plantInstance.source_notes,
              cost: plantInstance.cost,
              health_status: plantInstance.health_status,
              notes: plantInstance.notes,
            });
          }
        }
        
        // Update pin with plant references
        await supabase
          .from("pins")
          .update({
            plant_details_id: detailsId,
          })
          .eq("id", savedPin.id);
      }
      
      onSaved(savedPin);
      onClose();
    } catch (error) {
      console.error("Error saving pin:", error);
      alert("Failed to save plant. Please try again.");
    }
  };

  const handleDelete = async () => {
    if (!draft || !isPin(draft)) return;

    if (!confirm("Delete this pin?")) return;

    try {
      const { error } = await supabase
        .from("pins")
        .delete()
        .eq("id", draft.id);

      if (error) throw error;
      onDeleted(draft.id);
    } catch (error) {
      console.error("Error deleting pin:", error);
      alert("Failed to delete pin");
    }
  };

  const handleFeaturedUpload = async (file: File) => {
    if (!draft || !isPin(draft)) return;

    setUploadingFeatured(true);
    try {
      await uploadPinMedia(draft.id, file);
      // Refresh the featured image
      const media = await getPinMedia(draft.id);
      setFeaturedUrl(media[0]?.url ?? null);
    } catch (error) {
      console.error("Error uploading featured image:", error);
      alert("Failed to upload image");
    } finally {
      setUploadingFeatured(false);
    }
  };

  const tabs: { id: EditorTab; label: string; icon: string }[] = [
    { id: 'basic', label: 'Basic Info', icon: '📝' },
    { id: 'plant_details', label: 'Plant Details', icon: '🌱' },
    { id: 'care_history', label: 'Care History', icon: '📅' },
    { id: 'photos', label: 'Photos', icon: '📸' },
    { id: 'notes', label: 'Notes', icon: '📋' },
  ];

  return (
    <div className={`drawer ${open ? "open" : ""}`} data-testid="drawer" onClick={onClose}>
      <div className="drawer-panel" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <div className="drag-handle" />
          <div className="title">
            {isPin(draft) ? "Edit Plant" : "Add New Plant"}
          </div>
          <button className="btn" onClick={onClose} aria-label="Close">
            ✕
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="drawer-tabs">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`drawer-tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              <span className="tab-icon">{tab.icon}</span>
              <span className="tab-label">{tab.label}</span>
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="drawer-body">
          {activeTab === 'basic' && (
            <BasicInfoTab
              draft={draft}
              setDraft={setDraft}
              featuredUrl={featuredUrl}
              uploadingFeatured={uploadingFeatured}
              onFeaturedUpload={handleFeaturedUpload}
              featuredInputRef={featuredInputRef}
            />
          )}
          
          {activeTab === 'plant_details' && (
            <PlantDetailsTab
              draft={draft}
              setDraft={setDraft}
              plantDetails={plantDetails}
              setPlantDetails={setPlantDetails}
              plantInstance={plantInstance}
              setPlantInstance={setPlantInstance}
            />
          )}
          
          {activeTab === 'care_history' && (
            <CareHistoryTab
              draft={draft}
              plantInstance={plantInstance}
              careEvents={careEvents}
              setCareEvents={setCareEvents}
            />
          )}
          
          {activeTab === 'photos' && (
            <PhotosTab
              draft={draft}
              onOpenPinGallery={onOpenPinGallery}
            />
          )}
          
          {activeTab === 'notes' && (
            <NotesTab
              draft={draft}
              setDraft={setDraft}
            />
          )}
        </div>

        {/* Action Buttons */}
        <div className="drawer-actions">
          {isPin(draft) && (
            <button className="btn danger" onClick={handleDelete}>
              Delete
            </button>
          )}
          <div className="drawer-actions-spacer" />
          <button className="btn" onClick={onClose}>
            Cancel
          </button>
          <button 
            className="btn primary" 
            onClick={handleSave}
            disabled={!isDirty}
          >
            {isPin(draft) ? "Save Changes" : "Create Plant"}
          </button>
        </div>
      </div>
    </div>
  );
}

// Tab Components
function BasicInfoTab({ 
  draft, 
  setDraft, 
  featuredUrl, 
  uploadingFeatured, 
  onFeaturedUpload, 
  featuredInputRef 
}: {
  draft: Draft | null;
  setDraft: (draft: Draft | null) => void;
  featuredUrl: string | null;
  uploadingFeatured: boolean;
  onFeaturedUpload: (file: File) => void;
  featuredInputRef: React.RefObject<HTMLInputElement | null>;
}) {
  if (!draft) return null;

  return (
    <div className="tab-content">
      <div className="basic-info-header">
        <h3>Basic Information</h3>
        <div className="ai-discovery-banner">
          <div className="ai-discovery-content">
            <div className="ai-discovery-icon">🤖</div>
            <div className="ai-discovery-text">
              <h5>Discover AI-Powered Plant Details</h5>
              <p>Switch to the "Plant Details" tab to automatically fill in care requirements, growth habits, and more!</p>
            </div>
            <div className="ai-discovery-arrow">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
      
      <div className="field">
        <label>Plant Name</label>
        <input
          type="text"
          value={draft.name || ""}
          onChange={(e) => setDraft({ ...draft, name: e.target.value })}
          placeholder="Enter plant name..."
        />
        <div className="field-hint">
          💡 Tip: Enter the plant name here, then switch to "Plant Details" for AI-powered auto-fill
        </div>
      </div>

      <div className="field">
        <label>Position</label>
        <div className="position-display">
          X: {draft.x.toFixed(2)}, Y: {draft.y.toFixed(2)}
        </div>
      </div>

      <div className="field">
        <label>Status</label>
        <select
          value={draft.status || 'active'}
          onChange={(e) => setDraft({ ...draft, status: e.target.value as 'active' | 'dormant' | 'removed' | 'dead' })}
        >
          <option value="active">Active</option>
          <option value="dormant">Dormant</option>
          <option value="removed">Removed</option>
          <option value="dead">Dead</option>
        </select>
      </div>

      <div className="field">
        <label>Notes</label>
        <textarea
          value={draft.notes || ""}
          onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
          placeholder="Add any notes about this plant..."
          rows={3}
        />
      </div>

      <div className="field">
        <label>Featured Photo</label>
        <div className="featured-photo">
          {featuredUrl ? (
            <img src={featuredUrl} alt="Featured plant photo" />
          ) : (
            <div className="photo-placeholder">
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7,10 12,15 17,10"/>
                <line x1="12" y1="15" x2="12" y2="3"/>
              </svg>
              <span>No featured photo</span>
            </div>
          )}
          <input
            ref={featuredInputRef}
            type="file"
            accept="image/*"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) onFeaturedUpload(file);
            }}
            style={{ display: "none" }}
          />
          <button
            type="button"
            onClick={() => featuredInputRef.current?.click()}
            disabled={uploadingFeatured}
            className="upload-btn"
          >
            {uploadingFeatured ? "Uploading..." : "Upload Photo"}
          </button>
        </div>
      </div>
    </div>
  );
}

function PlantDetailsTab({ 
  draft, 
  setDraft,
  plantDetails,
  setPlantDetails,
  plantInstance,
  setPlantInstance
}: { 
  draft: Draft | null; 
  setDraft: (draft: Draft | null) => void;
  plantDetails: PlantDetails | null;
  setPlantDetails: (details: PlantDetails | null) => void;
  plantInstance: PlantInstance | null;
  setPlantInstance: (instance: PlantInstance | null) => void;
}) {
  const [loading, setLoading] = useState(false);
  const [aiSearching, setAiSearching] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<AIPlantSearchResult[]>([]);
  const [showResults, setShowResults] = useState(false);

  // Load plant data when component mounts
  useEffect(() => {
    if (draft && isPin(draft) && !plantDetails) {
      loadPlantData(draft.id);
    }
  }, [draft, plantDetails]);

  // Pre-fill search with plant name when tab becomes active
  useEffect(() => {
    if (draft?.name && !searchQuery) {
      setSearchQuery(draft.name);
    }
  }, [draft?.name, searchQuery]);

  const loadPlantData = async (pinId: string) => {
    setLoading(true);
    try {
      const instance = await getPlantInstanceByPinId(pinId);
      if (instance) {
        setPlantInstance(instance);
        setPlantDetails(instance.plant_details || null);
      } else {
        // Create empty plant details for new plants
        setPlantDetails({
          id: '',
          name: draft?.name || '',
          scientific_name: '',
          common_names: [],
          family: '',
          genus: '',
          species: '',
          cultivar: '',
          growth_habit: 'perennial',
          hardiness_zones: [],
          sun_exposure: 'full_sun',
          water_needs: 'moderate',
          mature_height: undefined,
          mature_width: undefined,
          bloom_time: undefined,
          bloom_duration: undefined,
          flower_color: [],
          foliage_color: [],
          soil_type: undefined,
          soil_ph: undefined,
          fertilizer_needs: undefined,
          pruning_needs: undefined,
          planting_season: undefined,
          planting_depth: undefined,
          spacing: undefined,
          created_at: '',
          updated_at: '',
        });
        setPlantInstance({
          id: '',
          plant_details_id: '',
          bed_id: draft?.bed_id || '',
          pin_id: pinId,
          planted_date: undefined,
          source: undefined,
          source_notes: '',
          cost: undefined,
          health_status: 'good',
          notes: '',
          created_at: '',
          updated_at: '',
        });
      }
    } catch (error) {
      console.error('Error loading plant data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAISearch = async () => {
    const query = searchQuery.trim();
    if (!query) {
      alert('Please enter a search term.');
      return;
    }

    setAiSearching(true);
    try {
      const results = await searchPlants(query);
      setSearchResults(results);
      setShowResults(true);
    } catch (error) {
      console.error('Error searching for plant:', error);
      alert('Failed to search for plant. Please try again.');
    } finally {
      setAiSearching(false);
    }
  };

  const selectPlantResult = (result: AIPlantSearchResult) => {
    setPlantDetails({
      ...plantDetails!,
      name: result.name,
      scientific_name: result.scientific_name,
      common_names: result.common_names,
      family: result.family,
      genus: result.genus,
      species: result.species,
      growth_habit: result.growth_habit,
      hardiness_zones: result.hardiness_zones,
      sun_exposure: result.sun_exposure,
      water_needs: result.water_needs,
      mature_height: result.mature_height,
      mature_width: result.mature_width,
      bloom_time: result.bloom_time,
      bloom_duration: result.bloom_duration,
      flower_color: result.flower_color,
      foliage_color: result.foliage_color,
      soil_type: result.soil_type,
      soil_ph: result.soil_ph,
      fertilizer_needs: result.fertilizer_needs,
      pruning_needs: result.pruning_needs,
      planting_season: result.planting_season,
      planting_depth: result.planting_depth,
      spacing: result.spacing,
    });
    setSearchQuery(result.name);
    setShowResults(false);
  };

  if (loading) {
    return (
      <div className="tab-content">
        <div className="loading-spinner"></div>
        <p>Loading plant details...</p>
      </div>
    );
  }

  if (!plantDetails || !plantInstance) {
    return (
      <div className="tab-content">
        <p>No plant details available.</p>
      </div>
    );
  }

  return (
    <div className="tab-content plant-details-tab">
      {/* AI Welcome Section - Beautiful Hero Card */}
      {!plantDetails?.scientific_name && (
        <div className="ai-hero-card">
          <div className="ai-hero-background">
            <div className="ai-hero-pattern"></div>
          </div>
          <div className="ai-hero-content">
            <div className="ai-hero-icon">
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
              </svg>
            </div>
            <h3 className="ai-hero-title">AI-Powered Plant Discovery</h3>
            <p className="ai-hero-subtitle">
              Let our intelligent system automatically fill in comprehensive plant details for you
            </p>
            
            {/* Feature Cards Grid */}
            <div className="ai-features-grid">
              <div className="ai-feature-card">
                <div className="ai-feature-icon">🌱</div>
                <h5>Growth Details</h5>
                <p>Height, width, growth habit</p>
              </div>
              <div className="ai-feature-card">
                <div className="ai-feature-icon">☀️</div>
                <h5>Care Requirements</h5>
                <p>Sun, water, soil preferences</p>
              </div>
              <div className="ai-feature-card">
                <div className="ai-feature-icon">🌸</div>
                <h5>Blooming Info</h5>
                <p>Bloom time & characteristics</p>
              </div>
              <div className="ai-feature-card">
                <div className="ai-feature-icon">📅</div>
                <h5>Care Schedule</h5>
                <p>Planting & maintenance tips</p>
              </div>
            </div>

            {/* Search Section */}
            <div className="ai-search-card">
              <div className="search-card-header">
                <h5>🔍 Search for Your Plant</h5>
                <p>Enter a plant name to get started</p>
              </div>
              
              <div className="search-input-container">
                <div className="search-input-wrapper">
                  <svg className="search-input-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                  </svg>
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Try: Rose, Tomato, Lavender, Japanese Maple..."
                    className="modern-search-input"
                    onKeyPress={(e) => e.key === 'Enter' && handleAISearch()}
                  />
                </div>
                <button 
                  onClick={handleAISearch}
                  disabled={aiSearching || !searchQuery.trim()}
                  className="modern-search-button"
                >
                  {aiSearching ? (
                    <>
                      <div className="spinner spinner--sm" />
                      Searching...
                    </>
                  ) : (
                    'Search'
                  )}
                </button>
              </div>

              {/* Search Results */}
              {showResults && searchResults.length > 0 && (
                <div className="modern-search-results">
                  <div className="results-header">
                    <span className="results-count">Found {searchResults.length} plant{searchResults.length !== 1 ? 's' : ''}</span>
                    <button 
                      className="close-results-btn"
                      onClick={() => setShowResults(false)}
                    >
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M18 6L6 18M6 6l12 12"/>
                      </svg>
                    </button>
                  </div>
                  <div className="results-grid">
                    {searchResults.map((result, index) => (
                      <div 
                        key={index}
                        className="modern-result-card"
                        onClick={() => selectPlantResult(result)}
                      >
                        <div className="result-card-header">
                          <h6 className="result-name">{result.name}</h6>
                          <div className="result-arrow">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <path d="M5 12h14M12 5l7 7-7 7"/>
                            </svg>
                          </div>
                        </div>
                        {result.scientific_name && (
                          <p className="result-scientific">{result.scientific_name}</p>
                        )}
                        <div className="result-tags">
                          <span className="result-tag">
                            <span className="tag-icon">🌱</span>
                            {result.growth_habit}
                          </span>
                          <span className="result-tag">
                            <span className="tag-icon">☀️</span>
                            {result.sun_exposure.replace('_', ' ')}
                          </span>
                          <span className="result-tag">
                            <span className="tag-icon">💧</span>
                            {result.water_needs}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {showResults && searchResults.length === 0 && (
                <div className="modern-no-results">
                  <div className="no-results-icon">🔍</div>
                  <h6>No plants found</h6>
                  <p>Try a different search term or check the spelling</p>
                </div>
              )}

              {/* Search Tips */}
              <div className="search-tips">
                <h6>💡 Search Tips</h6>
                <div className="tips-grid">
                  <div className="tip-item">
                    <span className="tip-bullet">•</span>
                    <span>Use common names like "Rose" or "Tomato"</span>
                  </div>
                  <div className="tip-item">
                    <span className="tip-bullet">•</span>
                    <span>Try scientific names like "Rosa" or "Solanum lycopersicum"</span>
                  </div>
                  <div className="tip-item">
                    <span className="tip-bullet">•</span>
                    <span>Include variety names like "Peace Rose" or "Cherry Tomato"</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* AI Success Section - Beautiful Success Card */}
      {plantDetails?.scientific_name && (
        <div className="ai-success-card">
          <div className="success-card-header">
            <div className="success-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M20 6L9 17l-5-5"/>
              </svg>
            </div>
            <div className="success-content">
              <h4>AI Data Loaded Successfully!</h4>
              <p>Plant details have been automatically filled in. You can edit any field below.</p>
            </div>
          </div>
          
          <div className="success-summary">
            <div className="summary-grid">
              <div className="summary-item">
                <span className="summary-label">Species</span>
                <span className="summary-value">{plantDetails.scientific_name}</span>
              </div>
              <div className="summary-item">
                <span className="summary-label">Growth Habit</span>
                <span className="summary-value">{plantDetails.growth_habit}</span>
              </div>
              <div className="summary-item">
                <span className="summary-label">Sun Exposure</span>
                <span className="summary-value">{plantDetails.sun_exposure.replace('_', ' ')}</span>
              </div>
              <div className="summary-item">
                <span className="summary-label">Water Needs</span>
                <span className="summary-value">{plantDetails.water_needs}</span>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Plant Details Form - Modern Card Layout */}
      <div className="plant-details-form">
        <div className="form-section">
          <h4 className="section-title">Plant Species Details</h4>
          
          <div className="form-grid">
            <div className="form-field">
              <label>Plant Name</label>
              <input
                type="text"
                value={plantDetails.name}
                onChange={(e) => setPlantDetails({ ...plantDetails, name: e.target.value })}
                placeholder="e.g., Honeysuckle"
                className="modern-input"
              />
            </div>

            <div className="form-field">
              <label>Scientific Name</label>
              <input
                type="text"
                value={plantDetails.scientific_name || ''}
                onChange={(e) => setPlantDetails({ ...plantDetails, scientific_name: e.target.value })}
                placeholder="e.g., Lonicera japonica"
                className="modern-input"
              />
            </div>

            <div className="form-field">
              <label>Growth Habit</label>
              <select
                value={plantDetails.growth_habit}
                onChange={(e) => setPlantDetails({ ...plantDetails, growth_habit: e.target.value as PlantDetails['growth_habit'] })}
                className="modern-select"
              >
                <option value="annual">Annual</option>
                <option value="perennial">Perennial</option>
                <option value="biennial">Biennial</option>
                <option value="shrub">Shrub</option>
                <option value="tree">Tree</option>
                <option value="vine">Vine</option>
                <option value="groundcover">Groundcover</option>
              </select>
            </div>

            <div className="form-field">
              <label>Sun Exposure</label>
              <select
                value={plantDetails.sun_exposure}
                onChange={(e) => setPlantDetails({ ...plantDetails, sun_exposure: e.target.value as PlantDetails['sun_exposure'] })}
                className="modern-select"
              >
                <option value="full_sun">Full Sun</option>
                <option value="partial_sun">Partial Sun</option>
                <option value="partial_shade">Partial Shade</option>
                <option value="full_shade">Full Shade</option>
              </select>
            </div>

            <div className="form-field">
              <label>Water Needs</label>
              <select
                value={plantDetails.water_needs}
                onChange={(e) => setPlantDetails({ ...plantDetails, water_needs: e.target.value as PlantDetails['water_needs'] })}
                className="modern-select"
              >
                <option value="low">Low</option>
                <option value="moderate">Moderate</option>
                <option value="high">High</option>
              </select>
            </div>
          </div>
        </div>

        <div className="form-section">
          <h4 className="section-title">This Plant Instance</h4>
          
          <div className="form-grid">
            <div className="form-field">
              <label>Planted Date</label>
              <input
                type="date"
                value={plantInstance.planted_date || ''}
                onChange={(e) => setPlantInstance({ ...plantInstance, planted_date: e.target.value })}
                className="modern-input"
              />
            </div>

            <div className="form-field">
              <label>Source</label>
              <select
                value={plantInstance.source || ''}
                onChange={(e) => setPlantInstance({ ...plantInstance, source: e.target.value as PlantInstance['source'] })}
                className="modern-select"
              >
                <option value="">Select source...</option>
                <option value="nursery">Nursery</option>
                <option value="seed">Seed</option>
                <option value="cutting">Cutting</option>
                <option value="division">Division</option>
                <option value="gift">Gift</option>
                <option value="other">Other</option>
              </select>
            </div>

            <div className="form-field">
              <label>Health Status</label>
              <select
                value={plantInstance.health_status}
                onChange={(e) => setPlantInstance({ ...plantInstance, health_status: e.target.value as PlantInstance['health_status'] })}
                className="modern-select"
              >
                <option value="excellent">Excellent</option>
                <option value="good">Good</option>
                <option value="fair">Fair</option>
                <option value="poor">Poor</option>
                <option value="dead">Dead</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function CareHistoryTab({ 
  draft, 
  plantInstance,
  careEvents,
  setCareEvents
}: { 
  draft: Draft | null;
  plantInstance: PlantInstance | null;
  careEvents: CareEvent[];
  setCareEvents: (events: CareEvent[]) => void;
}) {
  const [showAddForm, setShowAddForm] = useState(false);
  const [newEvent, setNewEvent] = useState<Partial<CareEvent>>({
    event_type: 'watering',
    event_date: new Date().toISOString().split('T')[0],
    description: '',
    notes: '',
    cost: undefined,
    images: [],
  });

  const handleAddEvent = async () => {
    if (!plantInstance || !newEvent.description || !newEvent.event_date) {
      alert('Please fill in all required fields');
      return;
    }

    try {
      const event = await createCareEvent({
        plant_instance_id: plantInstance.id,
        event_type: newEvent.event_type!,
        event_date: newEvent.event_date,
        description: newEvent.description,
        notes: newEvent.notes || '',
        cost: newEvent.cost,
        images: newEvent.images || [],
      });

      setCareEvents([event, ...careEvents]);
      setNewEvent({
        event_type: 'watering',
        event_date: new Date().toISOString().split('T')[0],
        description: '',
        notes: '',
        cost: undefined,
        images: [],
      });
      setShowAddForm(false);
    } catch (error) {
      console.error('Error adding care event:', error);
      alert('Failed to add care event. Please try again.');
    }
  };

  const handleDeleteEvent = async (eventId: string) => {
    if (!confirm('Delete this care event?')) return;

    try {
      await deleteCareEvent(eventId);
      setCareEvents(careEvents.filter(event => event.id !== eventId));
    } catch (error) {
      console.error('Error deleting care event:', error);
      alert('Failed to delete care event. Please try again.');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getEventTypeIcon = (type: string) => {
    switch (type) {
      case 'watering': return '💧';
      case 'fertilizing': return '🌱';
      case 'pruning': return '✂️';
      case 'pest_treatment': return '🐛';
      case 'disease_treatment': return '💊';
      case 'transplanting': return '🔄';
      case 'harvesting': return '🌾';
      default: return '📝';
    }
  };

  return (
    <div className="tab-content">
      <div className="care-history-header">
        <h3>Care Events</h3>
        <button 
          className="btn primary" 
          onClick={() => setShowAddForm(true)}
          disabled={!plantInstance}
        >
          Add Care Event
        </button>
      </div>
      
      {!plantInstance && (
        <div className="no-plant-instance">
          <p>Create a plant instance first to track care events.</p>
        </div>
      )}

      {showAddForm && plantInstance && (
        <div className="add-care-event-form">
          <h4>Add New Care Event</h4>
          
          <div className="field">
            <label>Event Type</label>
            <select
              value={newEvent.event_type}
              onChange={(e) => setNewEvent({ ...newEvent, event_type: e.target.value as CareEvent['event_type'] })}
            >
              <option value="watering">Watering</option>
              <option value="fertilizing">Fertilizing</option>
              <option value="pruning">Pruning</option>
              <option value="pest_treatment">Pest Treatment</option>
              <option value="disease_treatment">Disease Treatment</option>
              <option value="transplanting">Transplanting</option>
              <option value="harvesting">Harvesting</option>
              <option value="other">Other</option>
            </select>
          </div>

          <div className="field">
            <label>Date</label>
            <input
              type="date"
              value={newEvent.event_date}
              onChange={(e) => setNewEvent({ ...newEvent, event_date: e.target.value })}
            />
          </div>

          <div className="field">
            <label>Description *</label>
            <input
              type="text"
              value={newEvent.description}
              onChange={(e) => setNewEvent({ ...newEvent, description: e.target.value })}
              placeholder="e.g., Deep watering after dry spell"
            />
          </div>

          <div className="field">
            <label>Notes</label>
            <textarea
              value={newEvent.notes}
              onChange={(e) => setNewEvent({ ...newEvent, notes: e.target.value })}
              placeholder="Additional notes..."
              rows={2}
            />
          </div>

          <div className="field">
            <label>Cost ($)</label>
            <input
              type="number"
              step="0.01"
              value={newEvent.cost || ''}
              onChange={(e) => setNewEvent({ ...newEvent, cost: e.target.value ? parseFloat(e.target.value) : undefined })}
              placeholder="0.00"
            />
          </div>

          <div className="form-actions">
            <button className="btn" onClick={() => setShowAddForm(false)}>
              Cancel
            </button>
            <button className="btn primary" onClick={handleAddEvent}>
              Add Event
            </button>
          </div>
        </div>
      )}
      
      <div className="care-events-list">
        {careEvents.length === 0 ? (
          <div className="no-events">
            <p>No care events recorded yet.</p>
            <p>Add your first care event to start tracking plant health.</p>
          </div>
        ) : (
          careEvents.map((event) => (
            <div key={event.id} className="care-event">
              <div className="event-header">
                <div className="event-icon">{getEventTypeIcon(event.event_type)}</div>
                <div className="event-info">
                  <div className="event-date">{formatDate(event.event_date)}</div>
                  <div className="event-type">{event.event_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</div>
                </div>
                <button 
                  className="event-delete-btn"
                  onClick={() => handleDeleteEvent(event.id)}
                  title="Delete event"
                >
                  ✕
                </button>
              </div>
              <div className="event-description">{event.description}</div>
              {event.notes && (
                <div className="event-notes">{event.notes}</div>
              )}
              {event.cost && (
                <div className="event-cost">Cost: ${event.cost.toFixed(2)}</div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

function PhotosTab({ draft, onOpenPinGallery }: { draft: Draft | null; onOpenPinGallery?: (args: { pinId: string }) => void }) {
  const [pinMedia, setPinMedia] = useState<Array<{ url: string; id: string; captured_at?: string | null }>>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load pin media when tab is active
  useEffect(() => {
    if (!draft || !isPin(draft)) return;
    
    const loadMedia = async () => {
      setLoading(true);
      try {
        const media = await getPinMedia(draft.id);
        setPinMedia(media);
      } catch (error) {
        console.error('Error loading pin media:', error);
        setPinMedia([]);
      } finally {
        setLoading(false);
      }
    };

    loadMedia();
  }, [draft]);

  if (!draft || !isPin(draft)) return null;

  const handleFileUpload = async (file: File) => {
    if (!draft || !isPin(draft)) return;

    setUploading(true);
    try {
      await uploadPinMedia(draft.id, file);
      // Refresh the media list
      const media = await getPinMedia(draft.id);
      setPinMedia(media);
    } catch (error) {
      console.error('Error uploading file:', error);
      alert('Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="tab-content">
      <div className="photos-header">
        <h3>Plant Photos</h3>
        <div className="photos-actions">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileUpload(file);
            }}
            style={{ display: "none" }}
          />
          <button 
            className="btn"
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
          >
            {uploading ? "Uploading..." : "Add Photo"}
          </button>
        </div>
      </div>
      
      {loading ? (
        <div className="photos-loading">
          <div className="loading-spinner"></div>
          <p>Loading photos...</p>
        </div>
      ) : pinMedia.length === 0 ? (
        <div className="photos-empty">
          <div className="photo-placeholder">
            <span>No photos yet</span>
            <p>Add your first photo to document this plant's growth</p>
          </div>
        </div>
      ) : (
        <div className="photos-grid">
          {pinMedia.map((media, index) => (
            <div key={media.id || index} className="photo-item">
              <img 
                src={media.url} 
                alt={`Plant photo ${index + 1}`}
                className="photo-thumbnail"
              />
              <div className="photo-overlay">
                <button 
                  className="photo-delete-btn"
                  onClick={async () => {
                    if (confirm('Delete this photo?')) {
                      // TODO: Implement photo deletion
                      console.log('Delete photo:', media.id);
                    }
                  }}
                  title="Delete photo"
                >
                  ✕
                </button>
              </div>
              <div className="photo-date-overlay">
                {media.captured_at ? (
                  <span className="photo-date">
                    {new Date(media.captured_at).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    })}
                  </span>
                ) : (
                  <span className="photo-date">No date</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function NotesTab({ draft, setDraft }: { draft: Draft | null; setDraft: (draft: Draft | null) => void }) {
  if (!draft) return null;

  return (
    <div className="tab-content">
      <div className="field">
        <span>Notes</span>
        <textarea
          value={draft.notes || ""}
          onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
          placeholder="Add notes about this plant..."
          rows={6}
        />
      </div>
    </div>
  );
}