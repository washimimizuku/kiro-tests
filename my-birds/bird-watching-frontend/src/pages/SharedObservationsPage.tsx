import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { observationsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Navigation from '../components/Navigation';
import ObservationCard from '../components/ObservationCard';
import LazyObservationMap from '../components/LazyObservationMap';
import LoadingSpinner from '../components/LoadingSpinner';
import { filterSharedObservationsWithCoordinates } from '../utils/coordinateUtils';
import type { Observation, ObservationWithUser } from '../types';
import './SharedObservationsPage.css';

const SharedObservationsPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [observations, setObservations] = useState<ObservationWithUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'map'>('list');

  useEffect(() => {
    loadSharedObservations();
  }, []);

  const loadSharedObservations = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await observationsAPI.getShared();
      setObservations(data);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load shared observations');
    } finally {
      setLoading(false);
    }
  };

  const handleCardClick = (observation: ObservationWithUser | Observation) => {
    navigate(`/observations/${observation.id}`);
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="shared-observations-page">
          <LoadingSpinner size="large" message="Loading shared observations..." />
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="shared-observations-page">
      <div className="page-header">
        <div className="header-content">
          <h1>Community Observations</h1>
          <p className="page-description">
            Explore bird sightings shared by the community
          </p>
        </div>
        {observations.length > 0 && (
          <div className="view-toggle">
            <button 
              onClick={() => setViewMode('list')} 
              className={`toggle-btn ${viewMode === 'list' ? 'active' : ''}`}
            >
              📋 List
            </button>
            <button 
              onClick={() => setViewMode('map')} 
              className={`toggle-btn ${viewMode === 'map' ? 'active' : ''}`}
            >
              🗺️ Map
            </button>
          </div>
        )}
      </div>

      {error && <div className="error-message">{error}</div>}

      {observations.length === 0 ? (
        <div className="empty-state">
          <p>No shared observations yet. Be the first to share!</p>
        </div>
      ) : viewMode === 'map' ? (
        <div className="map-view">
          <LazyObservationMap
            observations={filterSharedObservationsWithCoordinates(observations)}
            onMarkerClick={handleCardClick}
            height="600px"
          />
        </div>
      ) : (
        <div className="observations-grid">
          {observations.map((observation) => (
            <ObservationCard
              key={observation.id}
              observation={observation}
              currentUserId={user?.id}
              onClick={handleCardClick}
            />
          ))}
        </div>
      )}
    </div>
    </>
  );
};

export default SharedObservationsPage;
