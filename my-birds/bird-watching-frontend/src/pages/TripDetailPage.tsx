import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { tripsAPI, observationsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Navigation from '../components/Navigation';
import ObservationCard from '../components/ObservationCard';
import LazyObservationMap from '../components/LazyObservationMap';
import LoadingSpinner from '../components/LoadingSpinner';
import { filterTripObservationsWithCoordinates } from '../utils/coordinateUtils';
import type { TripWithObservations, Observation, UpdateObservationRequest } from '../types';
import './TripDetailPage.css';

const TripDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [tripData, setTripData] = useState<TripWithObservations | null>(null);
  const [userObservations, setUserObservations] = useState<Observation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddObservations, setShowAddObservations] = useState(false);

  useEffect(() => {
    if (id) {
      loadTripDetails();
      loadUserObservations();
    }
  }, [id]);

  const loadTripDetails = async () => {
    if (!id) return;

    try {
      setLoading(true);
      setError(null);
      const data = await tripsAPI.getById(id);
      setTripData(data);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load trip details');
    } finally {
      setLoading(false);
    }
  };

  const loadUserObservations = async () => {
    try {
      const observations = await observationsAPI.getAll();
      // Filter out observations that are already in this trip
      const unassignedObservations = observations.filter(obs => !obs.trip_id || obs.trip_id !== id);
      setUserObservations(unassignedObservations);
    } catch (err: any) {
      console.error('Failed to load user observations:', err);
    }
  };

  const handleAddObservationToTrip = async (observationId: string) => {
    if (!id) return;

    try {
      const updateData: UpdateObservationRequest = {
        trip_id: id,
      };
      await observationsAPI.update(observationId, updateData);
      await loadTripDetails();
      await loadUserObservations();
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to add observation to trip');
    }
  };

  const handleRemoveObservationFromTrip = async (observationId: string) => {
    try {
      const updateData: UpdateObservationRequest = {
        trip_id: undefined,
      };
      await observationsAPI.update(observationId, updateData);
      await loadTripDetails();
      await loadUserObservations();
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to remove observation from trip');
    }
  };

  const handleObservationClick = (observation: Observation) => {
    navigate(`/observations/${observation.id}`);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="trip-detail-page">
          <LoadingSpinner size="large" message="Loading trip details..." />
        </div>
      </>
    );
  }

  if (error || !tripData) {
    return (
      <>
        <Navigation />
        <div className="trip-detail-page">
          <div className="error-message">{error || 'Trip not found'}</div>
          <button onClick={() => navigate('/trips')} className="back-btn">
            Back to Trips
          </button>
        </div>
      </>
    );
  }

  const { trip, observations } = tripData;
  const isOwner = user?.id === trip.user_id;

  return (
    <>
      <Navigation />
      <div className="trip-detail-page">
      <div className="page-header">
        <button onClick={() => navigate('/trips')} className="back-btn">
          ← Back to Trips
        </button>
      </div>

      <div className="trip-info-card">
        <h1>{trip.name}</h1>
        
        <div className="trip-details">
          <div className="trip-detail">
            <span className="detail-icon">📍</span>
            <span>{trip.location}</span>
          </div>
          <div className="trip-detail">
            <span className="detail-icon">📅</span>
            <span>{formatDate(trip.trip_date)}</span>
          </div>
          <div className="trip-detail">
            <span className="detail-icon">🔍</span>
            <span>{observations.length} {observations.length === 1 ? 'observation' : 'observations'}</span>
          </div>
        </div>

        {trip.description && (
          <div className="trip-description">
            <h3>Description</h3>
            <p>{trip.description}</p>
          </div>
        )}
      </div>

      {observations.length > 0 && filterTripObservationsWithCoordinates(observations, id!).length > 0 && (
        <div className="trip-map-section">
          <h2>Trip Map</h2>
          <LazyObservationMap
            observations={filterTripObservationsWithCoordinates(observations, id!)}
            onMarkerClick={handleObservationClick}
            height="400px"
          />
        </div>
      )}

      {observations.length > 0 && filterTripObservationsWithCoordinates(observations, id!).length === 0 && (
        <div className="trip-map-section">
          <h2>Trip Map</h2>
          <div className="no-coordinates-message">
            <p>No observations with coordinates yet. Add location data to your observations to see them on the map!</p>
          </div>
        </div>
      )}

      <div className="observations-section">
        <div className="section-header">
          <h2>Observations</h2>
          {isOwner && (
            <button 
              onClick={() => setShowAddObservations(!showAddObservations)}
              className="add-observation-btn"
            >
              {showAddObservations ? 'Cancel' : '+ Add Observation'}
            </button>
          )}
        </div>

        {showAddObservations && isOwner && (
          <div className="add-observations-panel">
            <h3>Add Existing Observations</h3>
            {userObservations.length === 0 ? (
              <p className="no-observations">No unassigned observations available.</p>
            ) : (
              <div className="observations-list">
                {userObservations.map((observation) => (
                  <div key={observation.id} className="observation-item">
                    <div className="observation-info">
                      <strong>{observation.species_name}</strong>
                      <span className="observation-location">{observation.location}</span>
                    </div>
                    <button
                      onClick={() => handleAddObservationToTrip(observation.id)}
                      className="add-btn"
                    >
                      Add
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {observations.length === 0 ? (
          <div className="empty-state">
            <p>No observations in this trip yet.</p>
            {isOwner && <p>Add existing observations or create new ones!</p>}
          </div>
        ) : (
          <div className="observations-grid">
            {observations.map((observation) => (
              <div key={observation.id} className="observation-wrapper">
                <ObservationCard
                  observation={observation}
                  currentUserId={user?.id}
                  onClick={handleObservationClick}
                />
                {isOwner && (
                  <button
                    onClick={() => handleRemoveObservationFromTrip(observation.id)}
                    className="remove-from-trip-btn"
                  >
                    Remove from Trip
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
    </>
  );
};

export default TripDetailPage;
