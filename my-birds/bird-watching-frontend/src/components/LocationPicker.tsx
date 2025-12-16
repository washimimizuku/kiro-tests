import React, { useState, useRef, useCallback } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import { Icon, Map as LeafletMap } from 'leaflet';
import { getCurrentPosition } from '../services/geolocation';
import { GeolocationError } from '../types';
import Tooltip from './Tooltip';
import './LocationPicker.css';

interface LocationPickerProps {
  latitude?: number;
  longitude?: number;
  onLocationChange: (lat: number, lng: number) => void;
  onLocationClear: () => void;
}

// Custom marker icon
const markerIcon = new Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

// Component to handle map clicks
const MapClickHandler: React.FC<{
  onLocationSelect: (lat: number, lng: number) => void;
}> = ({ onLocationSelect }) => {
  useMapEvents({
    click: (e) => {
      onLocationSelect(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
};

// Component to handle tile loading errors
const TileErrorHandler: React.FC<{
  onTileError: () => void;
  onTileLoad: () => void;
}> = ({ onTileError, onTileLoad }) => {
  useMapEvents({
    tileerror: () => {
      onTileError();
    },
    tileload: () => {
      onTileLoad();
    },
  });
  return null;
};

// Component to handle marker dragging
const DraggableMarker: React.FC<{
  position: [number, number];
  onDragEnd: (lat: number, lng: number) => void;
}> = ({ position, onDragEnd }) => {
  const markerRef = useRef<any>(null);

  const eventHandlers = {
    dragend() {
      const marker = markerRef.current;
      if (marker != null) {
        const pos = marker.getLatLng();
        onDragEnd(pos.lat, pos.lng);
      }
    },
  };

  return (
    <Marker
      draggable={true}
      eventHandlers={eventHandlers}
      position={position}
      ref={markerRef}
      icon={markerIcon}
    />
  );
};

const LocationPicker: React.FC<LocationPickerProps> = ({
  latitude,
  longitude,
  onLocationChange,
  onLocationClear,
}) => {
  const [isLoadingLocation, setIsLoadingLocation] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tileError, setTileError] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  const [tileKey, setTileKey] = useState(0);
  const maxRetries = 3;
  const mapRef = useRef<LeafletMap | null>(null);

  // Default center (if no coordinates provided)
  const defaultCenter: [number, number] = [40.7128, -74.0060]; // New York
  const center: [number, number] = 
    latitude !== undefined && longitude !== undefined
      ? [latitude, longitude]
      : defaultCenter;

  const hasCoordinates = latitude !== undefined && longitude !== undefined;

  const handleLocationSelect = useCallback((lat: number, lng: number) => {
    onLocationChange(lat, lng);
    setError(null);
  }, [onLocationChange]);

  const handleMarkerDragEnd = useCallback((lat: number, lng: number) => {
    onLocationChange(lat, lng);
  }, [onLocationChange]);

  const handleUseCurrentLocation = async () => {
    setIsLoadingLocation(true);
    setError(null);

    try {
      const coords = await getCurrentPosition();
      onLocationChange(coords.latitude, coords.longitude);
      
      // Pan map to new location
      if (mapRef.current) {
        mapRef.current.setView([coords.latitude, coords.longitude], 13);
      }
    } catch (err) {
      if (err instanceof GeolocationError) {
        setError(err.message);
      } else {
        setError('Failed to get current location');
      }
    } finally {
      setIsLoadingLocation(false);
    }
  };

  const handleClearLocation = () => {
    onLocationClear();
    setError(null);
  };

  const handleTileError = useCallback(() => {
    if (retryCount < maxRetries) {
      // Retry after a delay
      setTimeout(() => {
        setRetryCount(prev => prev + 1);
        setTileKey(prev => prev + 1);
      }, 2000);
    } else {
      setTileError(true);
    }
  }, [retryCount]);

  const handleTileLoad = useCallback(() => {
    // Reset error state when tiles load successfully
    if (tileError) {
      setTileError(false);
      setRetryCount(0);
    }
  }, [tileError]);

  const handleRetryTiles = () => {
    setTileError(false);
    setRetryCount(0);
    setTileKey(prev => prev + 1);
  };

  const formatCoordinate = (value: number, type: 'lat' | 'lng'): string => {
    const direction = type === 'lat' 
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'W');
    return `${Math.abs(value).toFixed(6)}° ${direction}`;
  };

  return (
    <div className="location-picker">
      <div className="location-picker-help">
        <p className="help-text">
          📍 Click on the map to select a location, use your current GPS position, or drag the marker to adjust the coordinates.
        </p>
      </div>
      
      <div className="location-picker-controls">
        <Tooltip content="Use your device's GPS to automatically capture your current location. You may need to grant location permissions.">
          <button
            type="button"
            onClick={handleUseCurrentLocation}
            disabled={isLoadingLocation}
            className="btn-use-location"
          >
            {isLoadingLocation ? 'Getting Location...' : '📍 Use Current Location'}
          </button>
        </Tooltip>
        
        {hasCoordinates && (
          <button
            type="button"
            onClick={handleClearLocation}
            className="btn-clear-location"
          >
            ✕ Clear Location
          </button>
        )}
      </div>

      {error && (
        <div className="location-picker-error">
          {error}
        </div>
      )}

      <div className="location-picker-map">
        {tileError && (
          <div className="map-tile-error">
            <p>⚠️ Map tiles failed to load. Please check your internet connection.</p>
            <button onClick={handleRetryTiles} className="retry-btn">
              Retry
            </button>
          </div>
        )}
        <MapContainer
          center={center}
          zoom={hasCoordinates ? 13 : 4}
          style={{ height: '100%', width: '100%' }}
          ref={mapRef}
        >
          <TileLayer
            key={tileKey}
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          
          <TileErrorHandler onTileError={handleTileError} onTileLoad={handleTileLoad} />
          <MapClickHandler onLocationSelect={handleLocationSelect} />
          
          {hasCoordinates && (
            <DraggableMarker
              position={[latitude, longitude]}
              onDragEnd={handleMarkerDragEnd}
            />
          )}
        </MapContainer>
      </div>

      {hasCoordinates && (
        <div className="location-picker-coordinates">
          <Tooltip content="Latitude measures north-south position from -90° (South Pole) to +90° (North Pole)">
            <div className="coordinate-display">
              <span className="coordinate-label">Latitude:</span>
              <span className="coordinate-value">{formatCoordinate(latitude, 'lat')}</span>
            </div>
          </Tooltip>
          <Tooltip content="Longitude measures east-west position from -180° to +180° (Prime Meridian at 0°)">
            <div className="coordinate-display">
              <span className="coordinate-label">Longitude:</span>
              <span className="coordinate-value">{formatCoordinate(longitude, 'lng')}</span>
            </div>
          </Tooltip>
          <div className="coordinate-decimal">
            {latitude.toFixed(6)}, {longitude.toFixed(6)}
          </div>
        </div>
      )}
    </div>
  );
};

export default LocationPicker;
