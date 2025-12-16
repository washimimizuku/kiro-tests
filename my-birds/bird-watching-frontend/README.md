# Bird Watching Platform - Frontend

React + TypeScript frontend for the Bird Watching Platform.

## Prerequisites

- Node.js 18+ (recommended: 20+)
- npm or yarn

## Setup

1. Copy `.env.example` to `.env` and update the values:
   ```bash
   cp .env.example .env
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

The application will start at `http://localhost:5173`

## Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## Testing

Run tests:
```bash
npm test
```

## Geolocation Features

The frontend includes comprehensive map and geolocation capabilities:

### Map Components

#### ObservationMap
Displays observations on an interactive Leaflet map with marker clustering.

```tsx
import ObservationMap from './components/ObservationMap';

<ObservationMap
  observations={observations}
  center={[40.7128, -74.0060]}
  zoom={10}
  onMarkerClick={(obs) => console.log(obs)}
  height="500px"
/>
```

Features:
- Automatic marker clustering for performance (>100 markers)
- Popup details on marker click
- Responsive design
- Lazy loading for better performance

#### LocationPicker
Interactive map for selecting coordinates in observation forms.

```tsx
import LocationPicker from './components/LocationPicker';

<LocationPicker
  latitude={latitude}
  longitude={longitude}
  onLocationChange={(lat, lng) => setCoordinates(lat, lng)}
  onLocationClear={() => clearCoordinates()}
/>
```

Features:
- Click to select location
- Draggable marker
- "Use Current Location" button (browser GPS)
- Coordinate display in multiple formats
- Built-in help text and tooltips

### Geolocation Service

Browser geolocation integration with error handling:

```typescript
import { getCurrentPosition } from './services/geolocation';

try {
  const coords = await getCurrentPosition();
  console.log(coords.latitude, coords.longitude);
} catch (error) {
  // Handle permission denied, timeout, or unavailable errors
}
```

### Coordinate Utilities

Formatting and validation utilities:

```typescript
import {
  formatCoordinate,
  formatCoordinateWithDirection,
  formatForGPS,
  isValidLatitude,
  isValidLongitude
} from './utils/coordinateUtils';

// Format with 6 decimal places
formatCoordinate(40.785091, 'lat'); // "40.785091° N"

// Format with direction
formatCoordinateWithDirection(40.785091, -73.968285);
// "40.785091° N, 73.968285° W"

// GPS format
formatForGPS(40.785091, -73.968285);
// "40.785091, -73.968285"

// Validation
isValidLatitude(95); // false (out of range)
isValidLongitude(-73.968285); // true
```

### Proximity Search

Search for observations near any location:

```typescript
import { observationsAPI } from './services/api';

const results = await observationsAPI.searchNearby({
  lat: 40.7128,
  lng: -74.0060,
  radius: 10, // kilometers
  species: 'Robin' // optional filter
});

// Results include distance_km field
results.forEach(obs => {
  console.log(`${obs.species_name} - ${obs.distance_km}km away`);
});
```

### Map Views

Maps are integrated into multiple pages:
- **ObservationsPage**: Toggle between list and map view
- **TripDetailPage**: Map showing all trip observations
- **SharedObservationsPage**: Community map with all shared observations
- **ObservationDetailPage**: Small map centered on observation location

### User Guidance

All geolocation features include:
- Tooltips explaining functionality
- Help text for complex interactions
- Error messages for permission/validation issues
- Visual feedback for loading states

## Project Structure

```
src/
├── pages/           # Page components (Login, Dashboard, etc.)
├── components/      # Reusable UI components (maps, forms, etc.)
│   ├── ObservationMap.tsx      # Map display component
│   ├── LocationPicker.tsx      # Coordinate selection component
│   ├── LazyLocationPicker.tsx  # Lazy-loaded wrapper
│   └── Tooltip.tsx             # Tooltip component
├── services/        # API service layer
│   ├── api.ts                  # API client (includes proximity search)
│   └── geolocation.ts          # Browser geolocation service
├── utils/           # Utility functions
│   └── coordinateUtils.ts      # Coordinate formatting/validation
├── contexts/        # React contexts for state management
├── types/           # TypeScript type definitions
└── assets/          # Static assets (images, etc.)
```

## Technology Stack

- React 19
- TypeScript
- Vite (build tool)
- React Router (routing)
- Axios (HTTP client)
- **Leaflet** (mapping library)
- **React Leaflet** (React bindings for Leaflet)
- **React Leaflet Cluster** (marker clustering)
- ESLint (linting)
- Vitest (testing)
