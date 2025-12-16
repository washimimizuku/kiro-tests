import React, { useState } from 'react';
import type { Trip, CreateTripRequest, UpdateTripRequest } from '../types';
import './TripForm.css';

interface TripFormProps {
  trip?: Trip;
  onSubmit: (data: CreateTripRequest | UpdateTripRequest) => Promise<void>;
  onCancel?: () => void;
}

const TripForm: React.FC<TripFormProps> = ({ trip, onSubmit, onCancel }) => {
  const [formData, setFormData] = useState({
    name: trip?.name || '',
    trip_date: trip?.trip_date 
      ? new Date(trip.trip_date).toISOString().slice(0, 16)
      : new Date().toISOString().slice(0, 16),
    location: trip?.location || '',
    description: trip?.description || '',
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    try {
      const submitData = {
        name: formData.name,
        trip_date: new Date(formData.trip_date).toISOString(),
        location: formData.location,
        description: formData.description || undefined,
      };

      await onSubmit(submitData);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to save trip');
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="trip-form">
      {error && <div className="error-message">{error}</div>}

      <div className="form-group">
        <label htmlFor="name">Trip Name *</label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleInputChange}
          required
          placeholder="e.g., Spring Migration Watch"
        />
      </div>

      <div className="form-group">
        <label htmlFor="trip_date">Date & Time *</label>
        <input
          type="datetime-local"
          id="trip_date"
          name="trip_date"
          value={formData.trip_date}
          onChange={handleInputChange}
          max={new Date().toISOString().slice(0, 16)}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="location">Location *</label>
        <input
          type="text"
          id="location"
          name="location"
          value={formData.location}
          onChange={handleInputChange}
          required
          placeholder="e.g., Central Park, New York"
        />
      </div>

      <div className="form-group">
        <label htmlFor="description">Description</label>
        <textarea
          id="description"
          name="description"
          value={formData.description}
          onChange={handleInputChange}
          rows={4}
          placeholder="Additional details about the trip..."
        />
      </div>

      <div className="form-actions">
        <button 
          type="submit" 
          disabled={submitting}
          className="submit-btn"
        >
          {submitting ? 'Saving...' : trip ? 'Update' : 'Create'} Trip
        </button>
        {onCancel && (
          <button 
            type="button" 
            onClick={onCancel}
            disabled={submitting}
            className="cancel-btn"
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
};

export default TripForm;
