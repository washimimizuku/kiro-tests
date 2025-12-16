import React, { Suspense, lazy } from 'react';
import LoadingSpinner from './LoadingSpinner';

// Lazy load the LocationPicker component
const LocationPicker = lazy(() => import('./LocationPicker'));

interface LazyLocationPickerProps {
  latitude?: number;
  longitude?: number;
  onLocationChange: (lat: number, lng: number) => void;
  onLocationClear: () => void;
}

/**
 * Lazy-loaded wrapper for LocationPicker component.
 * Defers loading of map resources until the component is rendered.
 * Shows a loading indicator while the location picker is being loaded.
 */
const LazyLocationPicker: React.FC<LazyLocationPickerProps> = (props) => {
  return (
    <Suspense 
      fallback={
        <div style={{ minHeight: '400px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <LoadingSpinner size="medium" message="Loading location picker..." />
        </div>
      }
    >
      <LocationPicker {...props} />
    </Suspense>
  );
};

export default LazyLocationPicker;
