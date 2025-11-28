import React, { Suspense, lazy } from 'react';
import LoadingSpinner from './LoadingSpinner';
import type { Observation, ObservationWithUser } from '../types';

// Lazy load the ObservationMap component
const ObservationMap = lazy(() => import('./ObservationMap'));

interface LazyObservationMapProps {
  observations: (Observation | ObservationWithUser)[];
  center?: [number, number];
  zoom?: number;
  onMarkerClick?: (observation: Observation | ObservationWithUser) => void;
  height?: string;
}

/**
 * Lazy-loaded wrapper for ObservationMap component.
 * Defers loading of map resources until the component is rendered.
 * Shows a loading indicator while the map component is being loaded.
 */
const LazyObservationMap: React.FC<LazyObservationMapProps> = (props) => {
  return (
    <Suspense 
      fallback={
        <div style={{ height: props.height || '500px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <LoadingSpinner size="medium" message="Loading map..." />
        </div>
      }
    >
      <ObservationMap {...props} />
    </Suspense>
  );
};

export default LazyObservationMap;
