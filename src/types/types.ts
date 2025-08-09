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
  x: number;      // 0..1
  y: number;      // 0..1
  name: string;
  notes: string | null;
  created_at?: string;
  updated_at?: string;
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