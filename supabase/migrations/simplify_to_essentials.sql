-- Migration: Simplify Plants de Louton to Essential Features
-- This migrates from complex botanical database to simple garden tracker

-- Step 1: Backup existing data (just in case)
CREATE TABLE IF NOT EXISTS pins_backup AS SELECT * FROM pins;

-- Step 2: Create new simplified schema
BEGIN;

-- Simple spaces for organization (was sections in beds)
CREATE TABLE IF NOT EXISTS spaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL, -- "Front yard", "Balcony", etc.
  icon text DEFAULT 'leaf.fill',
  color text DEFAULT 'green',
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Simplified beds table
CREATE TABLE IF NOT EXISTS beds_simple (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id uuid REFERENCES spaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  image_url text, -- Direct URL to image
  created_at timestamptz DEFAULT now()
);

-- Simplified pins table (this is all you really need!)
CREATE TABLE IF NOT EXISTS pins_simple (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bed_id uuid REFERENCES beds_simple(id) ON DELETE CASCADE,
  
  -- Location
  x decimal NOT NULL CHECK (x >= 0 AND x <= 1),
  y decimal NOT NULL CHECK (y >= 0 AND y <= 1),
  
  -- What's here
  name text NOT NULL,
  type text CHECK (type IN ('plant', 'structure', 'decoration', 'other')),
  
  -- Simple plant info (only if type = 'plant')
  sun_needs text CHECK (sun_needs IN ('full_sun', 'partial_sun', 'shade')),
  water_needs text CHECK (water_needs IN ('low', 'moderate', 'high')),
  planted_date date,
  
  -- Basic tracking
  notes text,
  last_care_date date,
  health text CHECK (health IN ('thriving', 'good', 'struggling', 'dead')),
  
  -- Media
  photo_url text,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 3: Migrate data from old to new
-- Migrate sections to spaces
INSERT INTO spaces (name, display_order)
SELECT DISTINCT 
  section,
  CASE 
    WHEN section ILIKE '%front%' THEN 1
    WHEN section ILIKE '%back%' THEN 2
    WHEN section ILIKE '%side%' THEN 3
    ELSE 4
  END
FROM beds
WHERE section IS NOT NULL
ON CONFLICT DO NOTHING;

-- Migrate beds
INSERT INTO beds_simple (id, space_id, name, image_url, created_at)
SELECT 
  b.id,
  s.id,
  b.name,
  b.image_url,
  b.created_at
FROM beds b
LEFT JOIN spaces s ON b.section = s.name;

-- Migrate pins (preserving the data you actually use)
INSERT INTO pins_simple (
  id, bed_id, x, y, name, type, notes, 
  last_care_date, health, created_at, updated_at
)
SELECT 
  p.id,
  p.bed_id,
  p.x,
  p.y,
  p.name,
  CASE 
    WHEN p.name IN ('Door', 'Pole') THEN 'structure'
    ELSE 'plant'
  END,
  p.notes,
  p.last_care_date,
  CASE 
    WHEN p.status = 'active' THEN 'good'
    WHEN p.status = 'dead' THEN 'dead'
    ELSE 'good'
  END,
  p.created_at,
  p.updated_at
FROM pins p;

-- Step 4: Create simple care tracking (if you want it)
CREATE TABLE IF NOT EXISTS care_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id uuid REFERENCES pins_simple(id) ON DELETE CASCADE,
  care_type text NOT NULL CHECK (care_type IN ('water', 'fertilize', 'prune', 'other')),
  care_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Step 5: Create indexes for performance
CREATE INDEX idx_pins_simple_bed ON pins_simple(bed_id);
CREATE INDEX idx_beds_simple_space ON beds_simple(space_id);
CREATE INDEX idx_care_log_pin ON care_log(pin_id);
CREATE INDEX idx_care_log_date ON care_log(care_date);

-- Step 6: Create views for easy querying
CREATE OR REPLACE VIEW garden_overview AS
SELECT 
  s.name as space_name,
  s.icon as space_icon,
  b.name as bed_name,
  b.image_url,
  COUNT(p.id) as pin_count,
  COUNT(CASE WHEN p.type = 'plant' THEN 1 END) as plant_count
FROM spaces s
LEFT JOIN beds_simple b ON s.id = b.space_id
LEFT JOIN pins_simple p ON b.id = p.bed_id
GROUP BY s.id, s.name, s.icon, b.id, b.name, b.image_url;

COMMIT;

-- Step 7: After verifying everything works, drop old tables
-- DO NOT RUN THESE UNTIL YOU'VE TESTED!
-- DROP TABLE IF EXISTS plant_details CASCADE;
-- DROP TABLE IF EXISTS plant_instances CASCADE;
-- DROP TABLE IF EXISTS care_events CASCADE;
-- DROP TABLE IF EXISTS plant_media CASCADE;
-- DROP TABLE IF EXISTS plant_search_cache CASCADE;
-- ALTER TABLE beds RENAME TO beds_old;
-- ALTER TABLE beds_simple RENAME TO beds;
-- ALTER TABLE pins RENAME TO pins_old;
-- ALTER TABLE pins_simple RENAME TO pins;
