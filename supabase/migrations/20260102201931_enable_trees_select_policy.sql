-- Enable RLS on trees table if not already enabled
ALTER TABLE trees ENABLE ROW LEVEL SECURITY;

-- Allow public (anon) users to SELECT all trees
CREATE POLICY "Allow public read access to trees"
ON trees
FOR SELECT
TO anon
USING (true);

-- Allow public (anon) users to INSERT trees (optional, if you want to allow direct inserts from client)
-- CREATE POLICY "Allow public insert access to trees"
-- ON trees
-- FOR INSERT
-- TO anon
-- WITH CHECK (true);
