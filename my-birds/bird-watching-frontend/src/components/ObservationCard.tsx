import React, { useState } from 'react';
import type { Observation, ObservationWithUser, ObservationWithDistance } from '../types';
import { formatCoordinateWithDirection, formatForGPS, hasCoordinates } from '../utils/coordinateUtils';
import './ObservationCard.css';

interface ObservationCardProps {
  observation: Observation | ObservationWithUser | ObservationWithDistance;
  currentUserId?: string;
  onEdit?: (observation: Observation) => void;
  onDelete?: (id: string) => void;
  onClick?: (observation: Observation | ObservationWithUser) => void;
  showDistance?: boolean;
}

const ObservationCard: React.FC<ObservationCardProps> = ({
  observation,
  currentUserId,
  onEdit,
  onDelete,
  onClick,
  showDistance = false,
}) => {
  const [copySuccess, setCopySuccess] = useState(false);
  const isOwner = currentUserId === observation.user_id;
  const observationWithUser = observation as ObservationWithUser;
  const observationWithDistance = observation as ObservationWithDistance;
  const hasUsername = 'username' in observation;
  const hasDistance = 'distance_km' in observation;
  const hasGeoCoordinates = hasCoordinates(observation);

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleCardClick = () => {
    if (onClick) {
      onClick(observation);
    }
  };

  const handleEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onEdit) {
      onEdit(observation);
    }
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onDelete && window.confirm('Are you sure you want to delete this observation?')) {
      onDelete(observation.id);
    }
  };

  const handleCopyCoordinates = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (observation.latitude !== undefined && observation.longitude !== undefined) {
      const gpsFormat = formatForGPS(observation.latitude, observation.longitude);
      try {
        await navigator.clipboard.writeText(gpsFormat);
        setCopySuccess(true);
        setTimeout(() => setCopySuccess(false), 2000);
      } catch (err) {
        console.error('Failed to copy coordinates:', err);
      }
    }
  };

  return (
    <div 
      className={`observation-card ${onClick ? 'clickable' : ''}`}
      onClick={handleCardClick}
    >
      {observation.photo_url && (
        <div className="observation-card-image">
          <img src={observation.photo_url} alt={observation.species_name} />
        </div>
      )}
      
      <div className="observation-card-content">
        <div className="observation-card-header">
          <h3 className="observation-species">{observation.species_name}</h3>
          {observation.is_shared && (
            <span className="shared-badge">Shared</span>
          )}
        </div>

        <div className="observation-card-details">
          <div className="observation-detail">
            <span className="detail-icon">📍</span>
            <span>{observation.location}</span>
          </div>
          <div className="observation-detail">
            <span className="detail-icon">📅</span>
            <span>{formatDate(observation.observation_date)}</span>
          </div>
          {hasUsername && (
            <div className="observation-detail">
              <span className="detail-icon">👤</span>
              <span>by {observationWithUser.username}</span>
            </div>
          )}
          {showDistance && hasDistance && (
            <div className="observation-detail distance-detail">
              <span className="detail-icon">📏</span>
              <span className="distance-value">
                {observationWithDistance.distance_km.toFixed(2)} km away
              </span>
            </div>
          )}
          {hasGeoCoordinates && observation.latitude !== undefined && observation.longitude !== undefined && (
            <div className="observation-detail coordinates-detail">
              <span className="detail-icon location-icon">🌍</span>
              <span className="coordinates-text">
                {formatCoordinateWithDirection(observation.latitude, observation.longitude)}
              </span>
              <div className="coordinates-actions">
                <a
                  href={`https://www.google.com/maps?q=${observation.latitude},${observation.longitude}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="map-link"
                  onClick={(e) => e.stopPropagation()}
                  title="View on Google Maps"
                >
                  View on Map
                </a>
                <button
                  onClick={handleCopyCoordinates}
                  className="copy-coordinates-btn"
                  title="Copy coordinates for GPS"
                >
                  {copySuccess ? '✓ Copied!' : '📋 Copy'}
                </button>
              </div>
            </div>
          )}
        </div>

        {observation.notes && (
          <p className="observation-notes">
            {observation.notes.length > 100
              ? `${observation.notes.substring(0, 100)}...`
              : observation.notes}
          </p>
        )}

        {isOwner && (onEdit || onDelete) && (
          <div className="observation-card-actions">
            {onEdit && (
              <button onClick={handleEdit} className="edit-btn">
                Edit
              </button>
            )}
            {onDelete && (
              <button onClick={handleDelete} className="delete-btn">
                Delete
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ObservationCard;
