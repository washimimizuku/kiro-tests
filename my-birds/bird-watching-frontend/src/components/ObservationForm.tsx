import React, { useState, useEffect } from 'react';
import { photosAPI } from '../services/api';
import type { Observation, CreateObservationRequest, UpdateObservationRequest } from '../types';
import { isValidLatitude, isValidLongitude } from '../utils/coordinateUtils';
import LazyLocationPicker from './LazyLocationPicker';
import Tooltip from './Tooltip';
import './ObservationForm.css';

interface ObservationFormProps {
  observation?: Observation;
  onSubmit: (data: CreateObservationRequest | UpdateObservationRequest) => Promise<void>;
  onCancel?: () => void;
}

const ObservationForm: React.FC<ObservationFormProps> = ({ observation, onSubmit, onCancel }) => {
  const [formData, setFormData] = useState({
    species_name: observation?.species_name || '',
    observation_date: observation?.observation_date 
      ? new Date(observation.observation_date).toISOString().slice(0, 16)
      : new Date().toISOString().slice(0, 16),
    location: observation?.location || '',
    notes: observation?.notes || '',
    is_shared: observation?.is_shared || false,
    latitude: observation?.latitude,
    longitude: observation?.longitude,
  });

  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(observation?.photo_url || null);
  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Cleanup preview URL on unmount
    return () => {
      if (photoPreview && photoPreview.startsWith('blob:')) {
        URL.revokeObjectURL(photoPreview);
      }
    };
  }, [photoPreview]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const checked = (e.target as HTMLInputElement).checked;
    
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        setError('Please select a valid image file');
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        setError('Image size must be less than 5MB');
        return;
      }

      setPhotoFile(file);
      setError(null);

      // Create preview
      const previewUrl = URL.createObjectURL(file);
      if (photoPreview && photoPreview.startsWith('blob:')) {
        URL.revokeObjectURL(photoPreview);
      }
      setPhotoPreview(previewUrl);
    }
  };

  const handleRemovePhoto = () => {
    setPhotoFile(null);
    if (photoPreview && photoPreview.startsWith('blob:')) {
      URL.revokeObjectURL(photoPreview);
    }
    setPhotoPreview(null);
  };

  const handleLocationChange = (lat: number, lng: number) => {
    setFormData(prev => ({
      ...prev,
      latitude: lat,
      longitude: lng,
    }));
  };

  const handleLocationClear = () => {
    setFormData(prev => ({
      ...prev,
      latitude: undefined,
      longitude: undefined,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validate coordinates if provided
    if (formData.latitude !== undefined || formData.longitude !== undefined) {
      // Both must be provided together
      if (formData.latitude === undefined || formData.longitude === undefined) {
        setError('Both latitude and longitude must be provided together, or neither');
        return;
      }

      // Validate latitude bounds
      if (!isValidLatitude(formData.latitude)) {
        setError('Latitude must be between -90 and 90 degrees');
        return;
      }

      // Validate longitude bounds
      if (!isValidLongitude(formData.longitude)) {
        setError('Longitude must be between -180 and 180 degrees');
        return;
      }
    }

    setSubmitting(true);

    try {
      let photo_url = observation?.photo_url;

      // Upload photo if a new one was selected
      if (photoFile) {
        setUploading(true);
        const uploadResponse = await photosAPI.upload(photoFile);
        photo_url = uploadResponse.photo_url;
        setUploading(false);
      } else if (!photoPreview) {
        // Photo was removed
        photo_url = undefined;
      }

      const submitData = {
        species_name: formData.species_name,
        observation_date: new Date(formData.observation_date).toISOString(),
        location: formData.location,
        notes: formData.notes || undefined,
        photo_url,
        is_shared: formData.is_shared,
        latitude: formData.latitude,
        longitude: formData.longitude,
      };

      await onSubmit(submitData);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to save observation');
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="observation-form">
      {error && <div className="error-message">{error}</div>}

      <div className="form-group">
        <label htmlFor="species_name">Species Name *</label>
        <input
          type="text"
          id="species_name"
          name="species_name"
          value={formData.species_name}
          onChange={handleInputChange}
          required
          placeholder="e.g., American Robin"
        />
      </div>

      <div className="form-group">
        <label htmlFor="observation_date">Date & Time *</label>
        <input
          type="datetime-local"
          id="observation_date"
          name="observation_date"
          value={formData.observation_date}
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
        <label>
          GPS Coordinates (Optional)
          <Tooltip content="Add precise GPS coordinates to your observation. This allows you to view observations on a map and search for nearby sightings. Coordinates are optional but recommended for accurate location tracking.">
            <span className="info-icon">ℹ️</span>
          </Tooltip>
        </label>
        <LazyLocationPicker
          latitude={formData.latitude}
          longitude={formData.longitude}
          onLocationChange={handleLocationChange}
          onLocationClear={handleLocationClear}
        />
      </div>

      <div className="form-group">
        <label htmlFor="notes">Notes</label>
        <textarea
          id="notes"
          name="notes"
          value={formData.notes}
          onChange={handleInputChange}
          rows={4}
          placeholder="Additional observations or notes..."
        />
      </div>

      <div className="form-group">
        <label htmlFor="photo">Photo</label>
        {photoPreview ? (
          <div className="photo-preview">
            <img src={photoPreview} alt="Preview" />
            <button type="button" onClick={handleRemovePhoto} className="remove-photo-btn">
              Remove Photo
            </button>
          </div>
        ) : (
          <input
            type="file"
            id="photo"
            accept="image/*"
            onChange={handlePhotoChange}
          />
        )}
      </div>

      <div className="form-group checkbox-group">
        <label>
          <input
            type="checkbox"
            name="is_shared"
            checked={formData.is_shared}
            onChange={handleInputChange}
          />
          <span>Share with community</span>
        </label>
      </div>

      <div className="form-actions">
        <button 
          type="submit" 
          disabled={submitting || uploading}
          className="submit-btn"
        >
          {uploading ? 'Uploading...' : submitting ? 'Saving...' : observation ? 'Update' : 'Create'} Observation
        </button>
        {onCancel && (
          <button 
            type="button" 
            onClick={onCancel}
            disabled={submitting || uploading}
            className="cancel-btn"
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
};

export default ObservationForm;
