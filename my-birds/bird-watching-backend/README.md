# Bird Watching Platform - Backend

Rust-based REST API backend for the Bird Watching Platform.

## Prerequisites

- Rust (latest stable)
- PostgreSQL 14+
- Docker (optional, for running PostgreSQL)

## Setup

1. Copy `.env.example` to `.env` and update the values:
   ```bash
   cp .env.example .env
   ```

2. Start PostgreSQL (using Docker):
   ```bash
   docker run --name bird-watching-db -e POSTGRES_PASSWORD=password -e POSTGRES_DB=bird_watching -p 5432:5432 -d postgres:14
   ```

3. Run migrations:
   ```bash
   cargo install sqlx-cli
   sqlx migrate run
   ```

4. Build and run the server:
   ```bash
   cargo run
   ```

The server will start at `http://127.0.0.1:8080`

## Testing

Run all tests:
```bash
cargo test
```

Run property-based tests:
```bash
cargo test --test '*properties*'
```

## Geolocation Features

The backend supports GPS coordinates for observations with the following capabilities:

### Database Schema
- Observations table includes optional `latitude` and `longitude` columns (DECIMAL)
- Indexed for efficient proximity searches
- Nullable to support observations without coordinates

### API Endpoints

#### Create/Update Observations with Coordinates
```json
POST /api/observations
PUT /api/observations/:id

{
  "species_name": "American Robin",
  "observation_date": "2024-01-15T10:30:00Z",
  "location": "Central Park",
  "latitude": 40.785091,
  "longitude": -73.968285,
  "notes": "Spotted near the lake",
  "is_shared": true
}
```

#### Proximity Search
```
GET /api/observations/nearby?lat=40.7128&lng=-74.0060&radius=10

Query Parameters:
- lat: Center latitude (required, -90 to 90)
- lng: Center longitude (required, -180 to 180)
- radius: Search radius in kilometers (required, > 0)
- species: Filter by species name (optional)

Response includes distance_km field for each observation.
```

### Coordinate Validation
- Latitude: Must be between -90 and 90 degrees
- Longitude: Must be between -180 and 180 degrees
- Both coordinates must be provided together, or neither
- Non-numeric values are rejected

### Distance Calculation
- Uses Haversine formula for great-circle distance
- Accurate for Earth's spherical approximation
- Returns distances in kilometers
- Handles edge cases (poles, date line crossing)

### Services
- `CoordinateValidator`: Validates coordinate bounds and pairs
- `GeoService`: Haversine distance calculation and proximity search

## Project Structure

```
src/
├── models/          # Domain entities (User, Observation, Trip)
├── api/             # HTTP route handlers
├── services/        # Business logic (auth, geo, coordinate validation)
├── repositories/    # Database access layer
├── middleware/      # Authentication and other middleware
└── utils/           # Utilities (errors, JWT)
migrations/          # Database migrations (includes coordinate columns)
tests/               # Integration and property tests (includes geolocation)
```
