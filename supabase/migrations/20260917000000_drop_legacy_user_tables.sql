-- User data moved onto the device (SwiftData + CloudKit).
--
-- Everything dropped here held per-user data or caches that are now local:
--   plants, sightings, tree_entries  -> Plant / Sighting SwiftData models
--   plant_log (view)                 -> denormalized onto Plant
--   plant_region_distribution        -> Plant.regionIds, refreshed from GBIF on-device
--   trees                            -> dead since the plants/sightings refactor
--   tree-photos bucket               -> Sighting.photo (externalStorage, synced as CKAsset)
--
-- regional_flora_cache is deliberately kept: its Pl@ntNet species counts are global,
-- expensive to compute, and identical for every user.
--
-- IF EXISTS throughout because these objects were created by hand in the dashboard and
-- never existed in migration history, so a fresh local stack will not have them.

DROP VIEW IF EXISTS plant_log;

DROP TABLE IF EXISTS sightings;
DROP TABLE IF EXISTS tree_entries;
DROP TABLE IF EXISTS plants;
DROP TABLE IF EXISTS trees;
DROP TABLE IF EXISTS plant_region_distribution;

DELETE FROM storage.objects WHERE bucket_id = 'tree-photos';
DELETE FROM storage.buckets WHERE id = 'tree-photos';
