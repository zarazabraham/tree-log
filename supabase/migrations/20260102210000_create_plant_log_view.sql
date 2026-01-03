-- Create a view that shows deduplicated plant logs
-- Groups by scientific name and shows the most recent sighting
CREATE VIEW plant_log AS
SELECT DISTINCT ON (scientific_name)
  id,
  scientific_name,
  identified_name,
  genus,
  family,
  common_names,
  gbif_id,
  powo_id,
  iucn_category,
  confidence,
  image_url,
  image_path,
  lat,
  lng,
  features,
  created_at AS last_seen
FROM trees
WHERE scientific_name IS NOT NULL
ORDER BY scientific_name, created_at DESC;

-- Add RLS policy for the view
-- Views inherit the security of underlying tables, but we can add explicit policy
CREATE POLICY "Allow public read access to plant_log"
ON trees
FOR SELECT
TO anon
USING (true);
