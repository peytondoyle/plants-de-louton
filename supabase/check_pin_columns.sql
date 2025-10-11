-- Quick check to see what columns the pins table actually has
-- Run this first to understand your pin relationships

-- 1. Show all columns in pins table
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'pins' 
ORDER BY ordinal_position;

-- 2. Check if specific plant-related columns exist
SELECT 
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pins' AND column_name = 'plant_id') as has_plant_id,
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pins' AND column_name = 'plant_instance_id') as has_plant_instance_id,
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pins' AND column_name = 'plant_details_id') as has_plant_details_id;

-- 3. Sample a few pins to see what data they contain
SELECT * FROM pins LIMIT 5;
