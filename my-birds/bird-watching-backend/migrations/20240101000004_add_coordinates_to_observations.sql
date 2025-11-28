-- Add latitude and longitude columns to observations table
-- Migration: Add geolocation support to observations

-- Add latitude column (nullable, DOUBLE PRECISION for floating-point coordinates)
-- Valid range: -90.0 to 90.0
ALTER TABLE observations
ADD COLUMN latitude DOUBLE PRECISION;

-- Add longitude column (nullable, DOUBLE PRECISION for floating-point coordinates)
-- Valid range: -180.0 to 180.0
ALTER TABLE observations
ADD COLUMN longitude DOUBLE PRECISION;

-- Create index on latitude and longitude for efficient proximity searches
-- Partial index: only index rows where both coordinates are present
CREATE INDEX idx_observations_coordinates 
ON observations(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Add comment to document the coordinate system
COMMENT ON COLUMN observations.latitude IS 'Latitude in decimal degrees (WGS84), range: -90 to 90';
COMMENT ON COLUMN observations.longitude IS 'Longitude in decimal degrees (WGS84), range: -180 to 180';
