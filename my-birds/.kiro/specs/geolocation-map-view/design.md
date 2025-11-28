# Design Document

## Overview

This feature adds geolocation capabilities to the Bird Watching Platform, enabling users to record precise GPS coordinates for their observations and visualize them on interactive maps. The implementation extends the existing observation model with optional latitude/longitude fields and adds map-based UI components using Leaflet.js for the frontend.

The backend will store coordinates as decimal degrees and provide APIs for proximity-based searches using the Haversine formula. The frontend will integrate browser geolocation APIs and display observations on interactive maps with clustering support for performance.

## Architecture

### Backend Changes

The backend will be extended with:
- Database schema updates to add latitude/longitude columns to observations table
- Validation logic for coordinate bounds
- Proximity search endpoint using Haversine distance calculation
- Updated observation API responses to include coordinate data

### Frontend Changes

The frontend will add:
- Map component using Leaflet.js library
- Geolocation service for browser GPS access
- Map markers for observation locations
- Interactive map for selecting coordinates in observation form
- Map views on observations page, trip details, and shared observations page
- Coordinate formatting utilities

### Data Flow

```
User Action → Browser Geolocation API → React Component
                                      ↓
                                 Coordinates
                                      ↓
                              Observation Form
                                      ↓
                              Backend API
                                      ↓
                              PostgreSQL (with PostGIS functions)
                                      ↓
                              Stored Observation
                                      ↓
                              Map Visualization
```

## Components and Interfaces

### Backend Components

#### 1. Database Schema Updates

**observations table modifications:**
```sql
ALTER TABLE observations
ADD COLUMN latitude DECIMAL(10, 8),
ADD COLUMN longitude DECIMAL(11, 8);

-- Add index for proximity searches
CREATE INDEX idx_observations_coordinates 
ON observations(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
```

#### 2. Updated Models

**Observation Model (Rust)**
```rust
struct Observation {
    id: Uuid,
    user_id: Uuid,
    trip_id: Option<Uuid>,
    species_name: String,
    observation_date: DateTime<Utc>,
    location: String,  // Text description
    latitude: Option<f64>,  // NEW
    longitude: Option<f64>, // NEW
    notes: Option<String>,
    photo_url: Option<String>,
    is_shared: bool,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

**CreateObservationRequest**
```rust
struct CreateObservationRequest {
    species_name: String,
    observation_date: DateTime<Utc>,
    location: String,
    latitude: Option<f64>,  // NEW
    longitude: Option<f64>, // NEW
    notes: Option<String>,
    photo_url: Option<String>,
    trip_id: Option<Uuid>,
    is_shared: bool,
}
```

#### 3. New API Endpoints

**Proximity Search**
- `GET /api/observations/nearby?lat={lat}&lng={lng}&radius={km}`
- Query parameters:
  - `lat`: Center latitude (required)
  - `lng`: Center longitude (required)
  - `radius`: Search radius in kilometers (required)
  - `user_id`: Filter by user (optional)
  - `species`: Filter by species (optional)
- Response: Array of observations with distance field

#### 4. Validation Service

**CoordinateValidator**
```rust
impl CoordinateValidator {
    fn validate_latitude(lat: f64) -> Result<(), ValidationError>
    fn validate_longitude(lng: f64) -> Result<(), ValidationError>
    fn validate_coordinate_pair(lat: Option<f64>, lng: Option<f64>) -> Result<(), ValidationError>
}
```

#### 5. Distance Calculation Service

**GeoService**
```rust
impl GeoService {
    // Calculate distance between two points using Haversine formula
    fn haversine_distance(
        lat1: f64, lng1: f64,
        lat2: f64, lng2: f64
    ) -> f64  // Returns distance in kilometers
    
    // Find observations within radius
    fn find_nearby_observations(
        center_lat: f64,
        center_lng: f64,
        radius_km: f64,
        filters: SearchFilters
    ) -> Result<Vec<ObservationWithDistance>>
}
```

### Frontend Components

#### 1. Map Component

**ObservationMap.tsx**
```typescript
interface ObservationMapProps {
    observations: Observation[];
    center?: [number, number];
    zoom?: number;
    onMarkerClick?: (observation: Observation) => void;
    height?: string;
}

// Displays observations on an interactive Leaflet map
// Supports marker clustering for performance
// Shows popups with observation details on marker click
```

#### 2. Location Picker Component

**LocationPicker.tsx**
```typescript
interface LocationPickerProps {
    latitude?: number;
    longitude?: number;
    onLocationChange: (lat: number, lng: number) => void;
    onLocationClear: () => void;
}

// Interactive map for selecting coordinates
// Allows clicking to set location
// Supports dragging marker to adjust
// Includes "Use Current Location" button
```

#### 3. Geolocation Service

**geolocation.ts**
```typescript
interface GeolocationService {
    getCurrentPosition(): Promise<{latitude: number, longitude: number}>;
    isSupported(): boolean;
    requestPermission(): Promise<PermissionState>;
}
```

#### 4. Coordinate Formatting Utilities

**coordinateUtils.ts**
```typescript
// Format coordinates with 6 decimal places
function formatCoordinate(value: number, type: 'lat' | 'lng'): string

// Format with directional indicators (N/S/E/W)
function formatCoordinateWithDirection(lat: number, lng: number): string

// Format for GPS devices (decimal degrees)
function formatForGPS(lat: number, lng: number): string

// Validate coordinate bounds
function isValidLatitude(lat: number): boolean
function isValidLongitude(lng: number): boolean
```

#### 5. Updated Pages

**ObservationsPage** - Add map view toggle showing all user observations
**TripDetailPage** - Add map showing trip observations with optional path
**SharedObservationsPage** - Add map showing all shared observations
**ObservationDetailPage** - Add small map centered on observation location

## Data Models

### API Request/Response Models

**CreateObservationRequest (Updated)**
```json
{
    "species_name": "string",
    "observation_date": "ISO8601 datetime",
    "location": "string",
    "latitude": "number (optional)",
    "longitude": "number (optional)",
    "notes": "string (optional)",
    "photo_url": "string (optional)",
    "trip_id": "uuid (optional)",
    "is_shared": "boolean"
}
```

**ObservationResponse (Updated)**
```json
{
    "id": "uuid",
    "user_id": "uuid",
    "username": "string",
    "trip_id": "uuid (optional)",
    "species_name": "string",
    "observation_date": "ISO8601 datetime",
    "location": "string",
    "latitude": "number (optional)",
    "longitude": "number (optional)",
    "notes": "string (optional)",
    "photo_url": "string (optional)",
    "is_shared": "boolean",
    "created_at": "ISO8601 datetime",
    "updated_at": "ISO8601 datetime"
}
```

**ObservationWithDistance**
```json
{
    ...ObservationResponse,
    "distance_km": "number"
}
```

**ProximitySearchRequest**
```
GET /api/observations/nearby?lat=40.7128&lng=-74.0060&radius=10&species=Cardinal
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Geolocation Storage Properties

**Property 1: Coordinate storage persistence**
*For any* observation created with valid latitude and longitude coordinates, retrieving that observation should return the same coordinate values.
**Validates: Requirements 1.1**

**Property 2: Optional coordinates acceptance**
*For any* observation created without coordinates (latitude and longitude both null), the observation should be created successfully and retrievable.
**Validates: Requirements 1.2**

**Property 3: Coordinate update persistence**
*For any* observation, updating its coordinates should result in the new coordinate values being persisted and retrievable in subsequent queries.
**Validates: Requirements 1.3**

### Validation Properties

**Property 4: Latitude bounds validation**
*For any* latitude value outside the range [-90, 90], creating or updating an observation with that latitude should be rejected with a validation error.
**Validates: Requirements 1.4, 9.1**

**Property 5: Longitude bounds validation**
*For any* longitude value outside the range [-180, 180], creating or updating an observation with that longitude should be rejected with a validation error.
**Validates: Requirements 1.5, 9.2**

**Property 6: Coordinate pair requirement**
*For any* observation creation or update request, if latitude is provided without longitude or vice versa, the request should be rejected requiring both or neither.
**Validates: Requirements 9.3**

**Property 7: Numeric coordinate validation**
*For any* observation request with non-numeric coordinate values, the request should be rejected with a validation error.
**Validates: Requirements 9.4**

### Formatting Properties

**Property 8: Coordinate precision formatting**
*For any* coordinate value, formatting it for display should produce a string with exactly 6 decimal places.
**Validates: Requirements 2.5, 7.1**

**Property 9: Directional coordinate formatting**
*For any* coordinate pair, formatting with directional indicators should include N or S for latitude and E or W for longitude based on the sign.
**Validates: Requirements 7.2**

**Property 10: GPS format compatibility**
*For any* coordinate pair, formatting for GPS devices should produce a string in decimal degrees format that can be parsed by standard GPS software.
**Validates: Requirements 7.4**

### Map Data Filtering Properties

**Property 11: Coordinate filtering for map display**
*For any* collection of observations, filtering for map display should include all and only observations where both latitude and longitude are non-null.
**Validates: Requirements 3.3**

**Property 12: Shared observations with coordinates**
*For any* query for shared observations with coordinates, the results should contain all and only observations where is_shared is true and both coordinates are non-null.
**Validates: Requirements 5.1, 5.3**

**Property 13: Trip observations with coordinates**
*For any* trip, querying observations for map display should return all and only observations associated with that trip where both coordinates are non-null.
**Validates: Requirements 6.1**

### Proximity Search Properties

**Property 14: Proximity search radius correctness**
*For any* center coordinates and radius, all observations returned by proximity search should have a calculated distance less than or equal to the specified radius.
**Validates: Requirements 8.1**

**Property 15: Haversine distance calculation**
*For any* two coordinate pairs, the Haversine distance calculation should produce a result that matches the great-circle distance within acceptable precision (0.1%).
**Validates: Requirements 8.2**

**Property 16: Distance inclusion in results**
*For any* proximity search result, each observation should include a distance_km field containing the calculated distance from the search center.
**Validates: Requirements 8.3**

## Error Handling

### Validation Errors (400)

- **Invalid Latitude**: "Latitude must be between -90 and 90 degrees"
- **Invalid Longitude**: "Longitude must be between -180 and 180 degrees"
- **Incomplete Coordinates**: "Both latitude and longitude must be provided together, or neither"
- **Non-numeric Coordinates**: "Coordinates must be numeric values"

### Geolocation Errors (Frontend)

- **Permission Denied**: "Location access denied. Please enable location permissions or enter coordinates manually."
- **Position Unavailable**: "Unable to determine your location. Please enter coordinates manually."
- **Timeout**: "Location request timed out. Please try again or enter coordinates manually."

### Map Errors (Frontend)

- **Tile Load Failure**: "Map tiles failed to load. Please check your internet connection."
- **Invalid Coordinates**: "Cannot display map: invalid coordinates"

## Testing Strategy

### Unit Testing

**Backend (Rust)**
- Test coordinate validation functions with boundary values
- Test Haversine distance calculation with known coordinate pairs
- Test coordinate pair validation logic
- Test proximity search query construction
- Test edge cases: null coordinates, boundary coordinates (poles, date line)

**Frontend (React)**
- Test coordinate formatting functions with various inputs
- Test coordinate validation functions
- Test geolocation service error handling
- Test map data filtering logic
- Test coordinate parsing and conversion

### Property-Based Testing

**Backend (Rust)**
- Property testing library: **proptest**
- Each property-based test MUST run a minimum of 100 iterations
- Each property-based test MUST be tagged with: `// Feature: geolocation-map-view, Property {number}: {property_text}`

**Property Test Coverage:**
- Generate random valid coordinates and verify storage/retrieval (Properties 1, 2, 3)
- Generate random invalid coordinates and verify rejection (Properties 4, 5, 6, 7)
- Generate random coordinate pairs and verify formatting (Properties 8, 9, 10)
- Generate random observation sets and verify filtering (Properties 11, 12, 13)
- Generate random search parameters and verify proximity results (Properties 14, 15, 16)

**Test Generators:**
```rust
// Generate valid latitude: -90.0 to 90.0
fn valid_latitude() -> impl Strategy<Value = f64>

// Generate valid longitude: -180.0 to 180.0
fn valid_longitude() -> impl Strategy<Value = f64>

// Generate invalid latitude: outside [-90, 90]
fn invalid_latitude() -> impl Strategy<Value = f64>

// Generate invalid longitude: outside [-180, 180]
fn invalid_longitude() -> impl Strategy<Value = f64>

// Generate coordinate pair
fn coordinate_pair() -> impl Strategy<Value = (f64, f64)>

// Generate observations with coordinates
fn observation_with_coords() -> impl Strategy<Value = Observation>
```

### Integration Testing

**Backend**
- Test proximity search endpoint with real database
- Test coordinate validation in API endpoints
- Test observation CRUD with coordinates
- Test migration adding coordinate columns

**Frontend**
- Test map component rendering with various observation sets
- Test location picker interaction
- Test geolocation service with mocked browser API
- Test coordinate display in observation views

## Security Considerations

### Data Privacy

- Coordinates reveal precise user locations - ensure proper sharing controls
- Only show coordinates for shared observations to other users
- Allow users to remove coordinates from observations
- Consider adding privacy zones (blur coordinates near home)

### Input Validation

- Validate coordinate bounds on both frontend and backend
- Prevent coordinate injection attacks
- Sanitize coordinate values before database storage
- Rate limit proximity search to prevent abuse

## Performance Considerations

### Backend Optimization

- Index on latitude/longitude columns for proximity searches
- Use spatial database functions (PostGIS) for efficient distance calculations
- Paginate proximity search results
- Cache frequently accessed coordinate data
- Consider using bounding box pre-filter before Haversine calculation

### Frontend Optimization

- Use marker clustering for maps with many observations (>100)
- Lazy load map library only when map component is visible
- Debounce map interaction events (pan, zoom)
- Limit number of markers rendered simultaneously
- Use tile caching for map backgrounds
- Implement virtual scrolling for observation lists with coordinates

### Database Considerations

For production, consider using PostGIS extension:
```sql
-- Enable PostGIS for advanced spatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Convert columns to geography type for better distance calculations
ALTER TABLE observations 
ADD COLUMN location_point geography(POINT, 4326);

-- Update point from lat/lng
UPDATE observations 
SET location_point = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Spatial index
CREATE INDEX idx_observations_location_point 
ON observations USING GIST(location_point);
```

## Technology Stack Additions

### Frontend
- **Map Library**: Leaflet.js 1.9+ (open source, lightweight)
- **React Leaflet**: React bindings for Leaflet
- **Marker Clustering**: react-leaflet-cluster or leaflet.markercluster
- **Map Tiles**: OpenStreetMap (free) or Mapbox (paid, better styling)

### Backend
- **Spatial Functions**: Native Rust Haversine implementation
- **Optional**: PostGIS extension for PostgreSQL (production)

### Dependencies

**Frontend package.json additions:**
```json
{
  "dependencies": {
    "leaflet": "^1.9.4",
    "react-leaflet": "^4.2.1",
    "react-leaflet-cluster": "^2.1.0"
  },
  "devDependencies": {
    "@types/leaflet": "^1.9.8"
  }
}
```

**Backend Cargo.toml additions:**
```toml
# No additional dependencies needed for basic Haversine
# For PostGIS support (optional):
# postgis = "0.9"
```

## Migration Strategy

### Database Migration

1. Add nullable latitude/longitude columns to observations table
2. Create index on coordinate columns
3. Existing observations will have null coordinates (backward compatible)
4. Users can update observations to add coordinates

### API Versioning

- Coordinate fields are optional in requests (backward compatible)
- Coordinate fields included in all responses (clients ignore if not needed)
- New proximity search endpoint doesn't affect existing endpoints

### Frontend Rollout

1. Add map library dependencies
2. Create map components
3. Update observation form to include coordinate fields
4. Add map views to existing pages
5. Feature flag for gradual rollout (optional)

## Future Enhancements

- Reverse geocoding: convert coordinates to address automatically
- Heatmap view showing observation density
- Drawing tools for marking territories or migration paths
- Offline map support for mobile apps
- Integration with eBird or other birding databases
- Weather data overlay on maps
- Elevation data for observations
- Import/export GPX tracks from GPS devices
