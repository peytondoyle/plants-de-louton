export type PlantPin = {
  id: string;
  section: string;
  plant_name: string;
  detailed_name?: string;
  image_url?: string;
  x?: number;
  y?: number;
  created_at?: string;
};

export type Bed = {
  id: string;
  section: string;
  name: string;
  main_image_id?: string | null;
  filmstrip_visible?: boolean | null;
  created_at?: string;
};

export type BedImage = {
  id: string;
  bed_id: string;
  image_path: string; // storage path, not full URL
  width?: number | null;
  height?: number | null;
  created_at: string;
};

export type Pin = {
  id: string;
  bed_id: string;
  image_id: string | null;
  name: string | null;
  notes: string | null;
  x: number;
  y: number;
  created_at: string;
  updated_at: string | null;
  plant_id?: string | null;
  image_url?: string | null; // optional per-pin image url from plant_pins view
  
  // New enhanced fields (all optional for backward compatibility)
  plant_instance_id?: string | null; // Links to specific plant instance
  plant_details_id?: string | null; // Links to plant species details
  status?: 'active' | 'dormant' | 'removed' | 'dead'; // Defaults to 'active' if not set
  last_care_date?: string;
  next_care_date?: string;
};

export type BedLatest = {
  id: string;
  section: string;
  name: string;
  created_at: string;
  image_path: string | null;
  image_created_at: string | null;
  pin_count: number;
};

// Enhanced Plant Management Types
export type PlantDetails = {
  id: string;
  name: string;
  scientific_name?: string;
  common_names?: string[];
  family?: string;
  genus?: string;
  species?: string;
  cultivar?: string;
  
  // Growth Characteristics
  growth_habit: 'annual' | 'perennial' | 'biennial' | 'shrub' | 'tree' | 'vine' | 'groundcover';
  hardiness_zones?: number[];
  sun_exposure: 'full_sun' | 'partial_sun' | 'partial_shade' | 'full_shade';
  water_needs: 'low' | 'moderate' | 'high';
  mature_height?: number; // in inches
  mature_width?: number; // in inches
  
  // Blooming & Seasons
  bloom_time?: 'spring' | 'summer' | 'fall' | 'winter' | 'year_round';
  bloom_duration?: number; // weeks
  flower_color?: string[];
  foliage_color?: string[];
  
  // Care Requirements
  soil_type?: 'clay' | 'loam' | 'sandy' | 'well_draining';
  soil_ph?: 'acidic' | 'neutral' | 'alkaline';
  fertilizer_needs?: 'low' | 'moderate' | 'high';
  pruning_needs?: 'minimal' | 'moderate' | 'heavy';
  
  // Planting Info
  planting_season?: 'spring' | 'summer' | 'fall' | 'winter';
  planting_depth?: number; // inches
  spacing?: number; // inches between plants
  
  created_at: string;
  updated_at: string;
};

export type PlantInstance = {
  id: string;
  plant_details_id: string;
  bed_id: string;
  pin_id: string;
  
  // Instance-specific data
  planted_date?: string;
  source?: 'nursery' | 'seed' | 'cutting' | 'division' | 'gift' | 'other';
  source_notes?: string;
  cost?: number;
  
  // Health & Status
  health_status: 'excellent' | 'good' | 'fair' | 'poor' | 'dead';
  notes?: string;
  
  created_at: string;
  updated_at: string;
  
  // Relationship data (loaded from joins)
  plant_details?: PlantDetails;
};

export type CareEvent = {
  id: string;
  plant_instance_id: string;
  event_type: 'watering' | 'fertilizing' | 'pruning' | 'pest_treatment' | 'disease_treatment' | 'transplanting' | 'harvesting' | 'other';
  event_date: string;
  description: string;
  notes?: string;
  cost?: number;
  images?: string[]; // URLs to care event photos
  
  created_at: string;
  updated_at: string;
};

// Plants & plant media (existing)
export type Plant = {
  id: string;
  name: string;
  scientific_name?: string | null;
  notes?: string | null;
  created_at: string;
};

export type PlantMedia = {
  id: string;
  plant_id: string;
  image_id?: string | null;
  pin_id?: string | null;
  storage_path: string;
  caption?: string | null;
  captured_at?: string | null;
  created_at: string;
  url?: string;
};