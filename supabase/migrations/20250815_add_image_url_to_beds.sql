-- Add image_url column to beds table
ALTER TABLE beds ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Populate image_url for beds that have images
UPDATE beds 
SET image_url = (
    SELECT 
        CASE 
            WHEN bi.image_path LIKE 'bed-%' THEN 
                -- For iOS app format (direct storage URLs)
                'https://edhyajfowwcgrdrazkwf.supabase.co/storage/v1/object/public/bed-images/' || bi.image_path
            ELSE 
                -- For web app format (plant-images bucket)
                'https://edhyajfowwcgrdrazkwf.supabase.co/storage/v1/object/public/plant-images/' || bi.image_path
        END
    FROM bed_images bi 
    WHERE bi.bed_id = beds.id 
    ORDER BY bi.created_at DESC 
    LIMIT 1
)
WHERE EXISTS (
    SELECT 1 FROM bed_images bi WHERE bi.bed_id = beds.id
);

-- Add index for better performance
CREATE INDEX IF NOT EXISTS beds_image_url_idx ON beds(image_url);
