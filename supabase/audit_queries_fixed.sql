-- Database Audit Queries for Plants de Louton (Fixed - checks table existence)
-- Run these queries one at a time or all together

-- 1. First, let's see what tables actually exist
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('pins', 'beds', 'bed_images', 'plant_details', 'plant_instances', 'plants', 'plant_media', 'care_events')
ORDER BY tablename;

-- 2. Overview of existing tables and row counts (safe version)
WITH table_counts AS (
  SELECT 'pins' as table_name, COUNT(*) as row_count FROM pins
  UNION ALL SELECT 'beds', COUNT(*) FROM beds
  UNION ALL SELECT 'bed_images', COUNT(*) FROM bed_images
  UNION ALL SELECT 'plant_details', COUNT(*) FROM plant_details
  UNION ALL SELECT 'plant_instances', COUNT(*) FROM plant_instances
  UNION ALL SELECT 'care_events', COUNT(*) FROM care_events
)
SELECT * FROM table_counts
ORDER BY row_count DESC;

-- 3. Understand pin relationships
SELECT 
  COUNT(*) as total_pins,
  COUNT(name) as has_name,
  COUNT(notes) as has_notes,
  COUNT(plant_instance_id) as has_plant_instance,
  COUNT(plant_details_id) as has_plant_details,
  COUNT(CASE WHEN plant_instance_id IS NOT NULL AND plant_details_id IS NOT NULL THEN 1 END) as has_both,
  COUNT(CASE WHEN plant_instance_id IS NULL AND plant_details_id IS NULL THEN 1 END) as has_neither,
  COUNT(status) as has_status,
  COUNT(last_care_date) as has_last_care,
  COUNT(featured_image_path) as has_featured_image
FROM pins;

-- 4. Check which plant_details columns are actually used
SELECT 
  COUNT(*) as total_plant_details,
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

-- 5. Check plant instances usage
SELECT 
  COUNT(*) as total_instances,
  COUNT(planted_date) as has_planted_date,
  COUNT(source) as has_source,
  COUNT(cost) as has_cost,
  COUNT(health_status) as has_health_status,
  COUNT(notes) as has_notes
FROM plant_instances;

-- 6. Analyze care events by type
SELECT 
  COALESCE(event_type, 'UNKNOWN') as event_type,
  COUNT(*) as count
FROM care_events
GROUP BY event_type
ORDER BY count DESC;

-- 7. Beds overview by section
SELECT 
  section,
  COUNT(*) as bed_count
FROM beds
GROUP BY section
ORDER BY section;

-- 8. Pin-Plant relationship analysis
SELECT 
  CASE 
    WHEN plant_instance_id IS NOT NULL THEN 'has_instance'
    WHEN plant_details_id IS NOT NULL THEN 'has_details_only'
    ELSE 'no_plant_ref'
  END as pin_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM pins
GROUP BY pin_type;

-- 9. Plant instances without pins (orphaned)
SELECT 
  COUNT(*) as total_instances,
  COUNT(CASE WHEN pi.id NOT IN (SELECT plant_instance_id FROM pins WHERE plant_instance_id IS NOT NULL) THEN 1 END) as orphaned_instances
FROM plant_instances pi;

-- 10. Storage usage by table
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size,
  ROUND(100.0 * pg_total_relation_size('public.'||tablename) / 
    SUM(pg_total_relation_size('public.'||tablename)) OVER (), 1) as percentage
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('pins', 'plant_details', 'plant_instances', 'beds', 'bed_images', 'care_events')
ORDER BY pg_total_relation_size('public.'||tablename) DESC;

-- 11. Sample pins with plant data to understand usage
SELECT 
  p.name as pin_name,
  pd.name as plant_species,
  pi.health_status,
  p.status as pin_status,
  p.last_care_date,
  CASE 
    WHEN p.plant_instance_id IS NOT NULL THEN 'Uses instances'
    WHEN p.plant_details_id IS NOT NULL THEN 'Uses details only'
    ELSE 'No plant link'
  END as plant_system
FROM pins p
LEFT JOIN plant_instances pi ON p.plant_instance_id = pi.id
LEFT JOIN plant_details pd ON COALESCE(pi.plant_details_id, p.plant_details_id) = pd.id
ORDER BY p.created_at DESC
LIMIT 20;
