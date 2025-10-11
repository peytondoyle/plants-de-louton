-- Safe Database Audit Queries for Plants de Louton
-- These queries check column existence first to avoid errors

-- 0. First, let's see what columns actually exist in the pins table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'pins' 
ORDER BY ordinal_position;

-- 1. Check which plant_details columns are actually used
SELECT 
  COUNT(*) as total_plants,
  COUNT(scientific_name) as has_scientific_name,
  COUNT(family) as has_family,
  COUNT(genus) as has_genus,
  COUNT(growth_habit) as has_growth_habit,
  COUNT(hardiness_zones) as has_zones,
  COUNT(soil_type) as has_soil_type,
  COUNT(soil_ph) as has_soil_ph,
  COUNT(mature_height) as has_height,
  COUNT(mature_width) as has_width,
  COUNT(bloom_time) as has_bloom_time,
  COUNT(planting_depth) as has_planting_depth
FROM plant_details;

-- 2. Basic pins count (safe version)
SELECT COUNT(*) as total_pins FROM pins;

-- 3. Check if these columns exist and have data
SELECT 
  COUNT(*) as total_pins,
  COUNT(name) as has_name,
  COUNT(notes) as has_notes,
  COUNT(x) as has_x,
  COUNT(y) as has_y
FROM pins;

-- 4. Check plant instances usage
SELECT 
  COUNT(*) as total_instances,
  COUNT(planted_date) as has_planted_date,
  COUNT(source) as has_source,
  COUNT(cost) as has_cost,
  COUNT(health_status) as has_health_status
FROM plant_instances;

-- 5. Analyze care events
SELECT 
  event_type,
  COUNT(*) as count
FROM care_events
GROUP BY event_type
ORDER BY count DESC;

-- 6. Check bed images
SELECT 
  COUNT(DISTINCT bed_id) as beds_with_images,
  COUNT(*) as total_images
FROM bed_images;

-- 7. Plants table usage
SELECT 
  COUNT(*) as total_plants,
  COUNT(scientific_name) as has_scientific_name,
  COUNT(notes) as has_notes
FROM plants;

-- 8. Check beds table
SELECT 
  COUNT(*) as total_beds,
  COUNT(DISTINCT section) as sections,
  string_agg(DISTINCT section, ', ') as section_names
FROM beds;

-- 9. Storage usage by table
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('pins', 'plants', 'plant_details', 'plant_instances', 'beds', 'bed_images', 'care_events')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
