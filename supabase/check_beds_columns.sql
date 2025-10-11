-- Let's check what columns your beds table actually has
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'beds' 
ORDER BY ordinal_position;
