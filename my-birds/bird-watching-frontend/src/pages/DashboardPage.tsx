import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { observationsAPI, tripsAPI } from '../services/api';
import Navigation from '../components/Navigation';
import LoadingSpinner from '../components/LoadingSpinner';
import type { Observation, Trip } from '../types';
import './DashboardPage.css';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [observations, setObservations] = useState<Observation[]>([]);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [observationsData, tripsData] = await Promise.all([
        observationsAPI.getAll(),
        tripsAPI.getAll(),
      ]);
      setObservations(observationsData);
      setTrips(tripsData);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  // Get recent observations (last 5)
  const recentObservations = observations
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 5);

  // Get recent trips (last 5)
  const recentTrips = trips
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 5);

  // Calculate statistics
  const totalObservations = observations.length;
  const uniqueSpecies = new Set(observations.map(obs => obs.species_name.toLowerCase())).size;
  const totalTrips = trips.length;

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="dashboard-page">
          <LoadingSpinner size="large" message="Loading dashboard..." />
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="dashboard-page">
      <div className="page-header">
        <h1>Dashboard</h1>
        <div className="welcome-text">Welcome, {user?.username}!</div>
      </div>

      {error && <div className="error-message">{error}</div>}

      {/* Statistics Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-value">{totalObservations}</div>
          <div className="stat-label">Total Observations</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{uniqueSpecies}</div>
          <div className="stat-label">Species Count</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{totalTrips}</div>
          <div className="stat-label">Total Trips</div>
        </div>
      </div>

      {/* Recent Observations and Trips */}
      <div className="content-grid">
        {/* Recent Observations */}
        <div className="section">
          <div className="section-header">
            <h2>Recent Observations</h2>
            <button onClick={() => navigate('/observations')} className="view-all-btn">
              View All
            </button>
          </div>
          {recentObservations.length === 0 ? (
            <div className="empty-state">
              <p>No observations yet.</p>
              <button onClick={() => navigate('/observations')} className="action-btn">
                Create Your First Observation
              </button>
            </div>
          ) : (
            <div className="items-list">
              {recentObservations.map((obs) => (
                <div
                  key={obs.id}
                  className="item-card"
                  onClick={() => navigate(`/observations/${obs.id}`)}
                >
                  <div className="item-header">
                    <h3>{obs.species_name}</h3>
                    <span className="item-date">{formatDate(obs.observation_date)}</span>
                  </div>
                  <div className="item-location">{obs.location}</div>
                  {obs.notes && (
                    <div className="item-notes">
                      {obs.notes.length > 100 ? `${obs.notes.substring(0, 100)}...` : obs.notes}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Trips */}
        <div className="section">
          <div className="section-header">
            <h2>Recent Trips</h2>
            <button onClick={() => navigate('/trips')} className="view-all-btn">
              View All
            </button>
          </div>
          {recentTrips.length === 0 ? (
            <div className="empty-state">
              <p>No trips yet.</p>
              <button onClick={() => navigate('/trips')} className="action-btn">
                Create Your First Trip
              </button>
            </div>
          ) : (
            <div className="items-list">
              {recentTrips.map((trip) => (
                <div
                  key={trip.id}
                  className="item-card"
                  onClick={() => navigate(`/trips/${trip.id}`)}
                >
                  <div className="item-header">
                    <h3>{trip.name}</h3>
                    <span className="item-date">{formatDate(trip.trip_date)}</span>
                  </div>
                  <div className="item-location">{trip.location}</div>
                  {trip.description && (
                    <div className="item-notes">
                      {trip.description.length > 100
                        ? `${trip.description.substring(0, 100)}...`
                        : trip.description}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="quick-actions">
        <h2>Quick Actions</h2>
        <div className="actions-grid">
          <button onClick={() => navigate('/observations')} className="quick-action-btn">
            <span className="action-icon">🦅</span>
            <span>My Observations</span>
          </button>
          <button onClick={() => navigate('/trips')} className="quick-action-btn">
            <span className="action-icon">🗺️</span>
            <span>My Trips</span>
          </button>
          <button onClick={() => navigate('/shared')} className="quick-action-btn">
            <span className="action-icon">🌍</span>
            <span>Shared Observations</span>
          </button>
        </div>
      </div>
    </div>
    </>
  );
};

export default DashboardPage;
