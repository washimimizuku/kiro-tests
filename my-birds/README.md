# Bird Watching Platform

A full-stack application for bird watchers to record observations, manage trips, and share sightings with the community.

## Project Structure

```
my-birds/
├── bird-watching-backend/    # Rust REST API backend
├── bird-watching-frontend/   # React TypeScript frontend
├── docker-compose.yml        # PostgreSQL database setup
└── .kiro/                    # Kiro spec files
```

## Quick Start

### 1. Start the Database

```bash
docker-compose up -d
```

This will start a PostgreSQL database on port 5432.

### 2. Start the Backend

```bash
cd bird-watching-backend
cp .env.example .env
cargo run
```

The API will be available at `http://localhost:8080`

### 3. Start the Frontend

```bash
cd bird-watching-frontend
cp .env.example .env
npm install
npm run dev
```

The frontend will be available at `http://localhost:5173`

## Features

- User authentication and registration
- Record bird observations with photos
- **GPS Geolocation**: Add precise coordinates to observations
- **Interactive Maps**: View observations on Leaflet-based maps with clustering
- **Proximity Search**: Find observations near any location
- Organize observations into trips
- Share observations with the community
- Search and filter observations
- Property-based testing for correctness

## Technology Stack

### Backend
- Rust
- Actix-web (web framework)
- SQLx (database)
- PostgreSQL
- JWT authentication
- Proptest (property-based testing)

### Frontend
- React 19
- TypeScript
- Vite
- React Router
- Axios

## Development

See individual README files in each directory for detailed setup and development instructions:
- [Backend README](./bird-watching-backend/README.md)
- [Frontend README](./bird-watching-frontend/README.md)

## Testing

### Backend Tests
```bash
cd bird-watching-backend
cargo test
```

### Frontend Tests
```bash
cd bird-watching-frontend
npm test
```

## Geolocation Features

The platform includes comprehensive geolocation capabilities:

### Recording Coordinates
- **Browser GPS**: Use your device's GPS to automatically capture your current location
- **Map Selection**: Click on an interactive map to select observation coordinates
- **Manual Entry**: Enter latitude and longitude values directly
- **Optional**: Coordinates are optional - observations work with or without them

### Map Visualization
- **Observation Maps**: View all your observations on an interactive map
- **Trip Maps**: See all observations from a trip plotted on a map
- **Shared Observations Map**: Explore community sightings on a map
- **Marker Clustering**: Automatic clustering for performance with many observations
- **Popup Details**: Click markers to view observation details

### Proximity Search
- **Near Me**: Search for observations near your current location
- **Custom Location**: Search near any coordinates
- **Radius Control**: Specify search radius in kilometers
- **Distance Display**: See how far each observation is from the search center

### Coordinate Display
- **Multiple Formats**: Coordinates shown in decimal degrees and directional format (N/S/E/W)
- **GPS Format**: Copy coordinates in a format suitable for GPS devices
- **External Maps**: Link to view locations on external map services
- **Validation**: Automatic validation of coordinate bounds

## Documentation

Full specification and design documents are available in `.kiro/specs/`:

### Bird Watching Platform
- [Requirements](./kiro/specs/bird-watching-platform/requirements.md)
- [Design](./kiro/specs/bird-watching-platform/design.md)
- [Tasks](./kiro/specs/bird-watching-platform/tasks.md)

### Geolocation Features
- [Requirements](./.kiro/specs/geolocation-map-view/requirements.md)
- [Design](./.kiro/specs/geolocation-map-view/design.md)
- [Tasks](./.kiro/specs/geolocation-map-view/tasks.md)
