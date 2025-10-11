-- Verify the migration worked correctly

-- 1. Check new tables exist
SELECT 'Tables Created:' as check_type, '' as result
UNION ALL
SELECT '  - spaces', EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'spaces')::text
UNION ALL
SELECT '  - beds_simple', EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'beds_simple')::text
UNION ALL
SELECT '  - pins_simple', EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'pins_simple')::text
UNION ALL
SELECT '  - care_log', EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'care_log')::text;

-- 2. Check data migration
SELECT '' as check_type, '' as result
UNION ALL
SELECT 'Data Migrated:', ''
UNION ALL
SELECT '  - Spaces', COUNT(*)::text || ' spaces created' FROM spaces
UNION ALL
SELECT '  - Beds', COUNT(*)::text || ' beds migrated' FROM beds_simple
UNION ALL
SELECT '  - Pins', COUNT(*)::text || ' pins migrated' FROM pins_simple;

-- 3. Sample the migrated data
SELECT '' as check_type, '' as result
UNION ALL
SELECT 'Sample Spaces:', '';

SELECT '  - ' || name || ' (order: ' || display_order || ')' as spaces_list
FROM spaces
ORDER BY display_order
LIMIT 5;

-- 4. Check garden overview
SELECT '' as check_type, '' as result
UNION ALL
SELECT 'Garden Overview:', '';

SELECT 
  '  - ' || space_name || ': ' || 
  COUNT(DISTINCT bed_name) || ' beds, ' || 
  SUM(pin_count) || ' pins (' || 
  SUM(plant_count) || ' plants)' as overview
FROM garden_overview
GROUP BY space_name
ORDER BY space_name;

-- 5. Sample migrated pins
SELECT '' as check_type, '' as result
UNION ALL
SELECT 'Sample Pins:', '';

SELECT 
  '  - ' || name || ' (' || type || ')' || 
  CASE WHEN health IS NOT NULL THEN ' - ' || health ELSE '' END as pin_info
FROM pins_simple
LIMIT 10;
