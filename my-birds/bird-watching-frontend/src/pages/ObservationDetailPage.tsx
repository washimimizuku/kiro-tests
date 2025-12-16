import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { observationsAPI, tripsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Navigation from '../components/Navigation';
import ObservationForm from '../components/ObservationForm';
import LazyObservationMap from '../components/LazyObservationMap';
import LoadingSpinner from '../components/LoadingSpinner';
import { formatCoordinateWithDirection, hasCoordinates } from '../utils/coordinateUtils';
import type { Observation, CreateObservationRequest, UpdateObservationRequest, Trip } from '../types';
import './ObservationDetailPage.css';

const ObservationDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [observation, setObservation] = useState<Observation | null>(null);
  const [trip, setTrip] = useState<Trip | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    if (id) {
      loadObservation();
    }
  }, [id]);

  const loadObservation = async () => {
    if (!id) return;

    try {
      setLoading(true);
      setError(null);
      const data = await observationsAPI.getById(id);
      setObservation(data);

      // Load trip if observation has one
      if (data.trip_id) {
        try {
          const tripData = await tripsAPI.getById(data.trip_id);
          setTrip(tripData.trip);
        } catch (err) {
          // Trip might not exist or user doesn't have access
          console.error('Failed to load trip:', err);
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load observation');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (data: CreateObservationRequest | UpdateObservationRequest) => {
    if (!observation) return;

    try {
      await observationsAPI.update(observation.id, data as UpdateObservationRequest);
      setIsEditing(false);
      await loadObservation();
    } catch (err: any) {
      throw err;
    }
  };

  const handleDelete = async () => {
    if (!observation) return;

    if (window.confirm('Are you sure you want to delete this observation?')) {
      try {
        await observationsAPI.delete(observation.id);
        navigate('/observations');
      } catch (err: any) {
        setError(err.response?.data?.error?.message || 'Failed to delete observation');
      }
    }
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
        <div className="observation-detail-page">
          <LoadingSpinner size="large" message="Loading observation..." />
        </div>
      </>
    );
  }

  if (error || !observation) {
    return (
      <>
        <Navigation />
        <div className="observation-detail-page">
          <div className="error-message">{error || 'Observation not found'}</div>
          <button onClick={() => navigate('/observations')} className="back-btn">
            Back to Observations
          </button>
        </div>
      </>
    );
  }

  const isOwner = user?.id === observation.user_id;

  if (isEditing && isOwner) {
    return (
      <>
        <Navigation />
        <div className="observation-detail-page">
          <div className="page-header">
            <h1>Edit Observation</h1>
          </div>
          <div className="form-container">
            <ObservationForm
              observation={observation}
              onSubmit={handleUpdate}
              onCancel={() => setIsEditing(false)}
            />
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="observation-detail-page">
      <div className="page-header">
        <button onClick={() => navigate('/observations')} className="back-btn">
          ← Back to Observations
        </button>
        {isOwner && (
          <div className="action-buttons">
            <button onClick={() => setIsEditing(true)} className="edit-btn">
              Edit
            </button>
            <button onClick={handleDelete} className="delete-btn">
              Delete
            </button>
          </div>
        )}
      </div>

      <div className="observation-detail-container">
        {observation.photo_url && (
          <div className="observation-photo">
            <img src={observation.photo_url} alt={observation.species_name} />
          </div>
        )}

        <div className="observation-info">
          <div className="observation-header">
            <h1>{observation.species_name}</h1>
            {observation.is_shared && (
              <span className="shared-badge">Shared with Community</span>
            )}
          </div>

          <div className="observation-details">
            <div className="detail-row">
              <span className="detail-label">📍 Location:</span>
              <span className="detail-value">{observation.location}</span>
            </div>
            <div className="detail-row">
              <span className="detail-label">📅 Date & Time:</span>
              <span className="detail-value">{formatDate(observation.observation_date)}</span>
            </div>
            {trip && (
              <div className="detail-row">
                <span className="detail-label">🗺️ Trip:</span>
                <span 
                  className="detail-value trip-link"
                  onClick={() => navigate(`/trips/${trip.id}`)}
                >
                  {trip.name}
                </span>
              </div>
            )}
            <div className="detail-row">
              <span className="detail-label">🕒 Created:</span>
              <span className="detail-value">{formatDate(observation.created_at)}</span>
            </div>
            {observation.updated_at !== observation.created_at && (
              <div className="detail-row">
                <span className="detail-label">✏️ Updated:</span>
                <span className="detail-value">{formatDate(observation.updated_at)}</span>
              </div>
            )}
          </div>

          {observation.notes && (
            <div className="observation-notes">
              <h3>Notes</h3>
              <p>{observation.notes}</p>
            </div>
          )}
        </div>

        {hasCoordinates(observation) ? (
          <div className="observation-location-section">
            <h3>Location</h3>
            <div className="coordinates-display">
              <p className="coordinates-text">
                {formatCoordinateWithDirection(observation.latitude!, observation.longitude!)}
              </p>
              <a
                href={`https://www.google.com/maps?q=${observation.latitude},${observation.longitude}`}
                target="_blank"
                rel="noopener noreferrer"
                className="external-map-link"
              >
                View on Google Maps →
              </a>
            </div>
            <div className="observation-map-container">
              <LazyObservationMap
                observations={[observation]}
                center={[observation.latitude!, observation.longitude!]}
                zoom={13}
                height="300px"
              />
            </div>
          </div>
        ) : (
          <div className="observation-location-section">
            <h3>Location</h3>
            <p className="no-coordinates">Location not specified</p>
          </div>
        )}
      </div>
    </div>
    </>
  );
};

export default ObservationDetailPage;
