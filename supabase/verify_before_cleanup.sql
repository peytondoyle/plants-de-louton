-- Run these checks BEFORE dropping old tables!

-- 1. Verify all pins migrated
SELECT 
  'Original pins:' as check,
  COUNT(*) as count 
FROM pins
UNION ALL
SELECT 
  'Migrated pins:',
  COUNT(*) 
FROM pins_simple;

-- 2. Verify all beds migrated
SELECT 
  'Original beds:' as check,
  COUNT(*) as count 
FROM beds
UNION ALL
SELECT 
  'Migrated beds:',
  COUNT(*) 
FROM beds_simple;

-- 3. Check for any pins that didn't migrate
SELECT 
  'Pins that might not have migrated:' as check,
  COUNT(*) as count
FROM pins p
WHERE NOT EXISTS (
  SELECT 1 FROM pins_simple ps WHERE ps.id = p.id
);

-- 4. Sample data from new tables
SELECT 'Sample migrated data:' as info;

SELECT 
  s.name as space,
  b.name as bed,
  COUNT(p.id) as pin_count
FROM spaces s
LEFT JOIN beds_simple b ON s.id = b.space_id
LEFT JOIN pins_simple p ON b.id = p.bed_id
GROUP BY s.name, b.name
ORDER BY s.name, b.name
LIMIT 10;

-- 5. Check if any apps are still using old tables
SELECT 
  'Recent activity on old tables (last 24h):' as check,
  COUNT(*) as updates
FROM pins 
WHERE updated_at > NOW() - INTERVAL '24 hours';
