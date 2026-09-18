-- User data moved onto the device (SwiftData + CloudKit).
--
-- Everything dropped here held per-user data or caches that are now local:
--   plants, sightings, tree_entries  -> Plant / Sighting SwiftData models
--   plant_log (view)                 -> denormalized onto Plant
--   plant_region_distribution        -> Plant.regionIds, refreshed from GBIF on-device
--   trees                            -> dead since the plants/sightings refactor
--
-- regional_flora_cache is deliberately kept: its Pl@ntNet species counts are global,
-- expensive to compute, and identical for every user.
--
-- IF EXISTS throughout because several of these were created by hand in the dashboard
-- of the local stack and never existed on the hosted project or in migration history.
--
-- The tree-photos storage bucket is NOT dropped here: Postgres rejects direct DML
-- against storage.objects ("Direct deletion from storage tables is not allowed").
-- Remove it through the Storage API or the dashboard instead. Sighting photos now live
-- on the device as externalStorage Data, synced by CloudKit.

DROP VIEW IF EXISTS plant_log;

DROP TABLE IF EXISTS sightings;
DROP TABLE IF EXISTS tree_entries;
DROP TABLE IF EXISTS plants;
DROP TABLE IF EXISTS trees;
DROP TABLE IF EXISTS plant_region_distribution;
