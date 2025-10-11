-- Database Audit Queries for Plants de Louton
-- Run these to understand actual data usage before cleanup

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

-- 2. Understand pin relationships
SELECT 
  COUNT(*) as total_pins,
  COUNT(plant_id) as has_plant_id,
  COUNT(plant_instance_id) as has_instance_id,
  COUNT(plant_details_id) as has_details_id,
  COUNT(CASE WHEN plant_id IS NOT NULL AND plant_instance_id IS NOT NULL THEN 1 END) as has_both,
  COUNT(CASE WHEN plant_id IS NULL AND plant_instance_id IS NULL AND plant_details_id IS NULL THEN 1 END) as has_none
FROM pins;

-- 3. Check plant instances usage
SELECT 
  COUNT(*) as total_instances,
  COUNT(planted_date) as has_planted_date,
  COUNT(source) as has_source,
  COUNT(cost) as has_cost,
  COUNT(health_status) as has_health_status
FROM plant_instances;

-- 4. Analyze care events
SELECT 
  event_type,
  COUNT(*) as count,
  AVG(CASE WHEN cost IS NOT NULL THEN 1 ELSE 0 END) as pct_with_cost
FROM care_events
GROUP BY event_type
ORDER BY count DESC;

-- 5. Check bed images
SELECT 
  COUNT(DISTINCT bed_id) as beds_with_images,
  COUNT(*) as total_images,
  AVG(image_count) as avg_images_per_bed
FROM (
  SELECT bed_id, COUNT(*) as image_count
  FROM bed_images
  GROUP BY bed_id
) t;

-- 6. Plants table usage
SELECT 
  COUNT(*) as total_plants,
  COUNT(scientific_name) as has_scientific_name,
  COUNT(notes) as has_notes
FROM plants;

-- 7. Find orphaned records
SELECT 'Pins without plants' as issue, COUNT(*) as count
FROM pins 
WHERE plant_id IS NULL AND plant_instance_id IS NULL AND plant_details_id IS NULL
UNION ALL
SELECT 'Plant instances without pins', COUNT(*)
FROM plant_instances pi
WHERE NOT EXISTS (SELECT 1 FROM pins WHERE plant_instance_id = pi.id)
UNION ALL
SELECT 'Plants without pins', COUNT(*)
FROM plants p
WHERE NOT EXISTS (SELECT 1 FROM pins WHERE plant_id = p.id);

-- 8. Storage usage by table
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
