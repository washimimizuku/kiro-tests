import React from 'react';
import type { Trip } from '../types';
import './TripCard.css';

interface TripCardProps {
  trip: Trip;
  observationCount?: number;
  currentUserId?: string;
  onEdit?: (trip: Trip) => void;
  onDelete?: (id: string) => void;
  onClick?: (trip: Trip) => void;
}

const TripCard: React.FC<TripCardProps> = ({
  trip,
  observationCount = 0,
  currentUserId,
  onEdit,
  onDelete,
  onClick,
}) => {
  const isOwner = currentUserId === trip.user_id;

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
      onClick(trip);
    }
  };

  const handleEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onEdit) {
      onEdit(trip);
    }
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onDelete && window.confirm('Are you sure you want to delete this trip? Observations will be preserved.')) {
      onDelete(trip.id);
    }
  };

  return (
    <div 
      className={`trip-card ${onClick ? 'clickable' : ''}`}
      onClick={handleCardClick}
    >
      <div className="trip-card-content">
        <div className="trip-card-header">
          <h3 className="trip-name">{trip.name}</h3>
          <span className="observation-count">
            {observationCount} {observationCount === 1 ? 'observation' : 'observations'}
          </span>
        </div>

        <div className="trip-card-details">
          <div className="trip-detail">
            <span className="detail-icon">📍</span>
            <span>{trip.location}</span>
          </div>
          <div className="trip-detail">
            <span className="detail-icon">📅</span>
            <span>{formatDate(trip.trip_date)}</span>
          </div>
        </div>

        {trip.description && (
          <p className="trip-description">
            {trip.description.length > 150
              ? `${trip.description.substring(0, 150)}...`
              : trip.description}
          </p>
        )}

        {isOwner && (onEdit || onDelete) && (
          <div className="trip-card-actions">
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

export default TripCard;
