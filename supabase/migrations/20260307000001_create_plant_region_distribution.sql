-- Cache for per-plant GBIF US state distribution data
-- Maps each plant key to the US region IDs where the species has been recorded
-- TTL is enforced by the edge function (30 days)

CREATE TABLE plant_region_distribution (
  plant_key   TEXT PRIMARY KEY,
  region_ids  TEXT[] NOT NULL DEFAULT '{}',
  fetched_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE plant_region_distribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to plant_region_distribution"
ON plant_region_distribution
FOR SELECT
TO anon
USING (true);
