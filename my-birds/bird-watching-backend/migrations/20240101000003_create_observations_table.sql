-- Create observations table
CREATE TABLE observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    species_name VARCHAR(255) NOT NULL,
    observation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    notes TEXT,
    photo_url VARCHAR(500),
    is_shared BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for frequently queried fields
CREATE INDEX idx_observations_user_id ON observations(user_id);
CREATE INDEX idx_observations_trip_id ON observations(trip_id);
CREATE INDEX idx_observations_species_name ON observations(species_name);
CREATE INDEX idx_observations_observation_date ON observations(observation_date);
CREATE INDEX idx_observations_is_shared ON observations(is_shared);
CREATE INDEX idx_observations_location ON observations(location);
