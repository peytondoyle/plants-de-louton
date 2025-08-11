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
  created_at?: string;
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

// Plants & plant media
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