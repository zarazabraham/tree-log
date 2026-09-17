-- Cache for PlantNet regional flora species counts
-- Keyed by PlantNet project ID (e.g. "k-europe", "k-north-america")
-- TTL is enforced by the edge function (7 days), not the DB

CREATE TABLE regional_flora_cache (
  project_id    TEXT PRIMARY KEY,
  project_name  TEXT NOT NULL,
  species_count INT  NOT NULL DEFAULT 0,
  fetched_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE regional_flora_cache ENABLE ROW LEVEL SECURITY;

-- Allow anon users (iOS app) to read cached data
CREATE POLICY "Allow public read access to regional_flora_cache"
ON regional_flora_cache
FOR SELECT
TO anon
USING (true);

-- Edge function uses the service role key to write, so no INSERT/UPDATE policy needed for anon
