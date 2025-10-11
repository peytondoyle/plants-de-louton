-- Database Audit Queries for Plants de Louton (Corrected for actual schema)
-- Run these queries to understand your data usage and cleanup opportunities

-- 1. Overview of all tables and row counts
SELECT 
  'pins' as table_name, COUNT(*) as row_count FROM pins
UNION ALL SELECT 'beds', COUNT(*) FROM beds
UNION ALL SELECT 'bed_images', COUNT(*) FROM bed_images
UNION ALL SELECT 'plant_details', COUNT(*) FROM plant_details
UNION ALL SELECT 'plant_instances', COUNT(*) FROM plant_instances
UNION ALL SELECT 'plants', COUNT(*) FROM plants
UNION ALL SELECT 'plant_media', COUNT(*) FROM plant_media
UNION ALL SELECT 'care_events', COUNT(*) FROM care_events
ORDER BY row_count DESC;

-- 2. Understand pin relationships (using actual columns)
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

-- 3. Check which plant_details columns are actually used
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
  COUNT(planting_depth) as has_planting_depth,
  COUNT(spacing) as has_spacing
FROM plant_details;

-- 4. Check plant instances usage
SELECT 
  COUNT(*) as total_instances,
  COUNT(planted_date) as has_planted_date,
  COUNT(source) as has_source,
  COUNT(cost) as has_cost,
  COUNT(health_status) as has_health_status,
  COUNT(notes) as has_notes
FROM plant_instances;

-- 5. Analyze care events by type
SELECT 
  COALESCE(event_type, 'UNKNOWN') as event_type,
  COUNT(*) as count
FROM care_events
GROUP BY event_type
ORDER BY count DESC;

-- 6. Check simple plants table (if you're using both systems)
SELECT 
  COUNT(*) as total_plants,
  COUNT(scientific_name) as has_scientific_name,
  COUNT(notes) as has_notes
FROM plants;

-- 7. Beds overview by section
SELECT 
  section,
  COUNT(*) as bed_count,
  COUNT(DISTINCT section) OVER () as total_sections
FROM beds
GROUP BY section
ORDER BY bed_count DESC;

-- 8. Find orphaned/inconsistent records
WITH pin_plant_status AS (
  SELECT 
    CASE 
      WHEN plant_instance_id IS NOT NULL THEN 'has_instance'
      WHEN plant_details_id IS NOT NULL THEN 'has_details_only'
      ELSE 'no_plant_ref'
    END as pin_type,
    COUNT(*) as count
  FROM pins
  GROUP BY pin_type
)
SELECT * FROM pin_plant_status;

-- 9. Plant instances without pins (orphaned)
SELECT COUNT(*) as orphaned_instances
FROM plant_instances pi
WHERE NOT EXISTS (
  SELECT 1 FROM pins p WHERE p.plant_instance_id = pi.id
);

-- 10. Storage usage by table
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('pins', 'plants', 'plant_details', 'plant_instances', 'beds', 'bed_images', 'care_events', 'plant_media')
ORDER BY pg_total_relation_size('public.'||tablename) DESC;

-- 11. Sample pins to see typical data
SELECT 
  p.name as pin_name,
  pd.name as plant_species,
  pi.health_status,
  p.status as pin_status,
  p.last_care_date
FROM pins p
LEFT JOIN plant_instances pi ON p.plant_instance_id = pi.id
LEFT JOIN plant_details pd ON COALESCE(pi.plant_details_id, p.plant_details_id) = pd.id
LIMIT 10;

-- 12. Check if you're using the complex plant system
SELECT 
  'Using plant_details/instances system' as check_type,
  CASE 
    WHEN COUNT(*) > 0 THEN 'YES (' || COUNT(*) || ' records)'
    ELSE 'NO'
  END as result
FROM plant_instances
UNION ALL
SELECT 
  'Using simple plants table',
  CASE 
    WHEN COUNT(*) > 0 THEN 'YES (' || COUNT(*) || ' records)'
    ELSE 'NO'
  END
FROM plants;
