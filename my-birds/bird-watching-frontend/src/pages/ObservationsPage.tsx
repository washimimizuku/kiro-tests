import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { observationsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Navigation from '../components/Navigation';
import ObservationCard from '../components/ObservationCard';
import ObservationForm from '../components/ObservationForm';
import LazyObservationMap from '../components/LazyObservationMap';
import SearchBar, { type SearchFilters, type ProximitySearchFilters } from '../components/SearchBar';
import LoadingSpinner from '../components/LoadingSpinner';
import { filterObservationsWithCoordinates } from '../utils/coordinateUtils';
import type { Observation, CreateObservationRequest, UpdateObservationRequest } from '../types';
import './ObservationsPage.css';

const ObservationsPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [observations, setObservations] = useState<Observation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editingObservation, setEditingObservation] = useState<Observation | null>(null);
  const [isSearching, setIsSearching] = useState(false);
  const [activeFilters, setActiveFilters] = useState<SearchFilters | null>(null);
  const [viewMode, setViewMode] = useState<'list' | 'map'>('list');
  const [isProximitySearch, setIsProximitySearch] = useState(false);

  useEffect(() => {
    loadObservations();
  }, []);

  const loadObservations = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await observationsAPI.getAll();
      setObservations(data);
      setIsSearching(false);
      setActiveFilters(null);
      setIsProximitySearch(false);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to load observations');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (filters: SearchFilters) => {
    try {
      setLoading(true);
      setError(null);
      const data = await observationsAPI.search(filters);
      setObservations(data);
      setIsSearching(true);
      setActiveFilters(filters);
      setIsProximitySearch(false);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to search observations');
    } finally {
      setLoading(false);
    }
  };

  const handleProximitySearch = async (filters: ProximitySearchFilters) => {
    try {
      setLoading(true);
      setError(null);
      const data = await observationsAPI.getNearby({
        lat: filters.lat,
        lng: filters.lng,
        radius: filters.radius,
        species: filters.species,
      });
      // Sort by distance
      const sortedData = [...data].sort((a, b) => a.distance_km - b.distance_km);
      setObservations(sortedData);
      setIsSearching(true);
      setIsProximitySearch(true);
      setActiveFilters(null);
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to search nearby observations');
    } finally {
      setLoading(false);
    }
  };

  const handleClearSearch = () => {
    loadObservations();
  };

  const handleCreate = async (data: CreateObservationRequest | UpdateObservationRequest) => {
    try {
      await observationsAPI.create(data as CreateObservationRequest);
      setShowForm(false);
      await loadObservations();
    } catch (err: any) {
      throw err;
    }
  };

  const handleUpdate = async (data: CreateObservationRequest | UpdateObservationRequest) => {
    if (!editingObservation) return;

    try {
      await observationsAPI.update(editingObservation.id, data as UpdateObservationRequest);
      setEditingObservation(null);
      setShowForm(false);
      await loadObservations();
    } catch (err: any) {
      throw err;
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await observationsAPI.delete(id);
      await loadObservations();
    } catch (err: any) {
      setError(err.response?.data?.error?.message || 'Failed to delete observation');
    }
  };

  const handleEdit = (observation: Observation) => {
    setEditingObservation(observation);
    setShowForm(true);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingObservation(null);
  };

  const handleNewObservation = () => {
    setEditingObservation(null);
    setShowForm(true);
  };

  const handleCardClick = (observation: Observation) => {
    navigate(`/observations/${observation.id}`);
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="observations-page">
          <LoadingSpinner size="large" message="Loading observations..." />
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="observations-page">
      <div className="page-header">
        <h1>My Observations</h1>
        <div className="header-actions">
          {!showForm && (
            <>
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
              <button onClick={handleNewObservation} className="new-observation-btn">
                + New Observation
              </button>
            </>
          )}
        </div>
      </div>

      {error && <div className="error-message">{error}</div>}

      {showForm ? (
        <div className="form-container">
          <h2>{editingObservation ? 'Edit Observation' : 'New Observation'}</h2>
          <ObservationForm
            observation={editingObservation || undefined}
            onSubmit={editingObservation ? handleUpdate : handleCreate}
            onCancel={handleCancel}
          />
        </div>
      ) : (
        <>
          <SearchBar 
            onSearch={handleSearch} 
            onProximitySearch={handleProximitySearch}
            onClear={handleClearSearch} 
          />
          
          {isSearching && (
            <div className="search-info">
              {isProximitySearch ? (
                <>
                  Showing observations within radius
                  <span> ({observations.length} found)</span>
                </>
              ) : activeFilters && (
                <>
                  Showing search results
                  {Object.keys(activeFilters).length > 0 && (
                    <span> ({observations.length} found)</span>
                  )}
                </>
              )}
            </div>
          )}

          {observations.length === 0 ? (
            <div className="empty-state">
              <p>
                {isSearching 
                  ? 'No observations match your search criteria.' 
                  : 'No observations yet. Create your first one!'}
              </p>
            </div>
          ) : viewMode === 'map' ? (
            <div className="map-view">
              <LazyObservationMap
                observations={filterObservationsWithCoordinates(observations)}
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
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                  onClick={handleCardClick}
                  showDistance={isProximitySearch}
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

export default ObservationsPage;
