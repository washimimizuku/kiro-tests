import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { tripsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Navigation from '../components/Navigation';
import TripCard from '../components/TripCard';
import TripForm from '../components/TripForm';
import LoadingSpinner from '../components/LoadingSpinner';
import type { Trip, CreateTripRequest, UpdateTripRequest } from '../types';
import './TripsPage.css';

const TripsPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editingTrip, setEditingTrip] = useState<Trip | null>(null);

  useEffect(() => {
    loadTrips();
  }, []);

  const loadTrips = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await tripsAPI.getAll();
      setTrips(data);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load trips');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (data: CreateTripRequest | UpdateTripRequest) => {
    try {
      await tripsAPI.create(data as CreateTripRequest);
      setShowForm(false);
      await loadTrips();
    } catch (err: any) {
      throw err;
    }
  };

  const handleUpdate = async (data: CreateTripRequest | UpdateTripRequest) => {
    if (!editingTrip) return;

    try {
      await tripsAPI.update(editingTrip.id, data as UpdateTripRequest);
      setEditingTrip(null);
      setShowForm(false);
      await loadTrips();
    } catch (err: any) {
      throw err;
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await tripsAPI.delete(id);
      await loadTrips();
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to delete trip');
    }
  };

  const handleEdit = (trip: Trip) => {
    setEditingTrip(trip);
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingTrip(null);
  };

  const handleNewTrip = () => {
    setEditingTrip(null);
    setShowForm(true);
  };

  const handleCardClick = (trip: Trip) => {
    navigate(`/trips/${trip.id}`);
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="trips-page">
          <LoadingSpinner size="large" message="Loading trips..." />
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="trips-page">
      <div className="page-header">
        <h1>My Trips</h1>
        {!showForm && (
          <button onClick={handleNewTrip} className="new-trip-btn">
            + New Trip
          </button>
        )}
      </div>

      {error && <div className="error-message">{error}</div>}

      {showForm ? (
        <div className="form-container">
          <h2>{editingTrip ? 'Edit Trip' : 'New Trip'}</h2>
          <TripForm
            trip={editingTrip || undefined}
            onSubmit={editingTrip ? handleUpdate : handleCreate}
            onCancel={handleCancel}
          />
        </div>
      ) : (
        <>
          {trips.length === 0 ? (
            <div className="empty-state">
              <p>No trips yet. Create your first one!</p>
            </div>
          ) : (
            <div className="trips-grid">
              {trips.map((trip) => (
                <TripCard
                  key={trip.id}
                  trip={trip}
                  observationCount={0}
                  currentUserId={user?.id}
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                  onClick={handleCardClick}
                />
              ))}
            </div>
          )}
        </>
      )}
    </div>
    </>
  );
};

export default TripsPage;
