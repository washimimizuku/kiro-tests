-- Rollback migration: Remove geolocation support from observations

-- Drop the coordinate index
DROP INDEX IF EXISTS idx_observations_coordinates;

-- Remove longitude column
ALTER TABLE observations
DROP COLUMN IF EXISTS longitude;

-- Remove latitude column
ALTER TABLE observations
DROP COLUMN IF EXISTS latitude;
