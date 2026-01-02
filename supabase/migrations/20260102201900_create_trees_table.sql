-- Create trees table
CREATE TABLE trees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  image_path TEXT,
  image_url TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  identified_name TEXT,
  scientific_name TEXT,
  genus TEXT,
  family TEXT,
  common_names TEXT[],
  gbif_id TEXT,
  powo_id TEXT,
  iucn_category TEXT,
  confidence DOUBLE PRECISION,
  features TEXT[]
);

-- Create index on created_at for faster sorting
CREATE INDEX trees_created_at_idx ON trees(created_at DESC);
