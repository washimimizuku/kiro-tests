import React, { useMemo, useState, useCallback } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import MarkerClusterGroup from 'react-leaflet-cluster';
import { Icon, LatLngBounds } from 'leaflet';
import type { Observation, ObservationWithUser } from '../types';
import './ObservationMap.css';

interface ObservationMapProps {
  observations: (Observation | ObservationWithUser)[];
  center?: [number, number];
  zoom?: number;
  onMarkerClick?: (observation: Observation | ObservationWithUser) => void;
  height?: string;
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

const ObservationMap: React.FC<ObservationMapProps> = ({
  observations,
  center,
  zoom = 10,
  onMarkerClick,
  height = '500px'
}) => {
  const [tileError, setTileError] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  const [tileKey, setTileKey] = useState(0);
  const maxRetries = 3;

  // Filter observations that have coordinates
  const observationsWithCoords = useMemo(() => {
    return observations.filter(obs => 
      obs.latitude !== undefined && 
      obs.latitude !== null && 
      obs.longitude !== undefined && 
      obs.longitude !== null
    );
  }, [observations]);

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

  const handleRetry = () => {
    setTileError(false);
    setRetryCount(0);
    setTileKey(prev => prev + 1);
  };

  // Calculate map center and bounds
  const { mapCenter, bounds } = useMemo(() => {
    if (center) {
      return { mapCenter: center, bounds: undefined };
    }

    if (observationsWithCoords.length === 0) {
      return { mapCenter: [0, 0] as [number, number], bounds: undefined };
    }

    if (observationsWithCoords.length === 1) {
      const obs = observationsWithCoords[0];
      return { 
        mapCenter: [obs.latitude!, obs.longitude!] as [number, number], 
        bounds: undefined 
      };
    }

    // Calculate bounds for multiple observations
    const latLngs = observationsWithCoords.map(obs => [obs.latitude!, obs.longitude!]);
    const boundsObj = new LatLngBounds(latLngs as [number, number][]);
    
    return { 
      mapCenter: boundsObj.getCenter() as unknown as [number, number], 
      bounds: boundsObj 
    };
  }, [observationsWithCoords, center]);

  // Handle empty observation list
  if (observationsWithCoords.length === 0) {
    return (
      <div className="observation-map-empty" style={{ height }}>
        <p>No observations with coordinates to display</p>
      </div>
    );
  }

  // Determine if clustering should be enabled based on marker count
  const shouldCluster = observationsWithCoords.length > 100;

  return (
    <div className="observation-map-container" style={{ height }}>
      {tileError && (
        <div className="map-tile-error">
          <p>⚠️ Map tiles failed to load. Please check your internet connection.</p>
          <button onClick={handleRetry} className="retry-btn">
            Retry
          </button>
        </div>
      )}
      <MapContainer
        center={mapCenter}
        zoom={zoom}
        bounds={bounds}
        boundsOptions={{ padding: [50, 50] }}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          key={tileKey}
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <TileErrorHandler onTileError={handleTileError} onTileLoad={handleTileLoad} />
        
        {shouldCluster ? (
          <MarkerClusterGroup
            chunkedLoading
            maxClusterRadius={80}
            spiderfyOnMaxZoom={true}
            showCoverageOnHover={false}
            zoomToBoundsOnClick={true}
            iconCreateFunction={(cluster: any) => {
              const count = cluster.getChildCount();
              let size = 'small';
              
              if (count >= 100) {
                size = 'large';
              } else if (count >= 10) {
                size = 'medium';
              }
              
              return new Icon({
                html: `<div><span>${count}</span></div>`,
                className: `marker-cluster marker-cluster-${size}`,
                iconSize: [40, 40]
              });
            }}
          >
            {observationsWithCoords.map((observation) => (
              <Marker
                key={observation.id}
                position={[observation.latitude!, observation.longitude!]}
                icon={markerIcon}
                eventHandlers={{
                  click: () => onMarkerClick?.(observation)
                }}
              >
                <Popup>
                  <div className="observation-popup">
                    <h3>{observation.species_name}</h3>
                    <p><strong>Location:</strong> {observation.location}</p>
                    <p><strong>Date:</strong> {new Date(observation.observation_date).toLocaleDateString()}</p>
                    {'username' in observation && (
                      <p><strong>Observer:</strong> {observation.username}</p>
                    )}
                    {observation.notes && (
                      <p><strong>Notes:</strong> {observation.notes}</p>
                    )}
                    <p className="coordinates">
                      {observation.latitude!.toFixed(6)}, {observation.longitude!.toFixed(6)}
                    </p>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MarkerClusterGroup>
        ) : (
          <>
            {observationsWithCoords.map((observation) => (
              <Marker
                key={observation.id}
                position={[observation.latitude!, observation.longitude!]}
                icon={markerIcon}
                eventHandlers={{
                  click: () => onMarkerClick?.(observation)
                }}
              >
                <Popup>
                  <div className="observation-popup">
                    <h3>{observation.species_name}</h3>
                    <p><strong>Location:</strong> {observation.location}</p>
                    <p><strong>Date:</strong> {new Date(observation.observation_date).toLocaleDateString()}</p>
                    {'username' in observation && (
                      <p><strong>Observer:</strong> {observation.username}</p>
                    )}
                    {observation.notes && (
                      <p><strong>Notes:</strong> {observation.notes}</p>
                    )}
                    <p className="coordinates">
                      {observation.latitude!.toFixed(6)}, {observation.longitude!.toFixed(6)}
                    </p>
                  </div>
                </Popup>
              </Marker>
            ))}
          </>
        )}
      </MapContainer>
    </div>
  );
};

export default ObservationMap;
