import React, { useState } from 'react';
import { getCurrentPosition } from '../services/geolocation';
import { GeolocationError } from '../types';
import type { ProximitySearchParams } from '../types';
import Tooltip from './Tooltip';
import './SearchBar.css';

export interface SearchFilters {
  species?: string;
  location?: string;
  start_date?: string;
  end_date?: string;
}

export type ProximitySearchFilters = Omit<ProximitySearchParams, 'user_id'>;

interface SearchBarProps {
  onSearch: (filters: SearchFilters) => void;
  onProximitySearch?: (filters: ProximitySearchFilters) => void;
  onClear?: () => void;
}

const SearchBar: React.FC<SearchBarProps> = ({ onSearch, onProximitySearch, onClear }) => {
  const [filters, setFilters] = useState<SearchFilters>({
    species: '',
    location: '',
    start_date: '',
    end_date: '',
  });
  const [proximityMode, setProximityMode] = useState(false);
  const [proximityFilters, setProximityFilters] = useState({
    lat: '',
    lng: '',
    radius: '10',
    species: '',
  });
  const [gettingLocation, setGettingLocation] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleProximityInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setProximityFilters(prev => ({
      ...prev,
      [name]: value,
    }));
    setLocationError(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (proximityMode && onProximitySearch) {
      // Validate proximity search inputs
      const lat = parseFloat(proximityFilters.lat);
      const lng = parseFloat(proximityFilters.lng);
      const radius = parseFloat(proximityFilters.radius);

      if (isNaN(lat) || isNaN(lng) || isNaN(radius)) {
        setLocationError('Please provide valid coordinates and radius');
        return;
      }

      if (lat < -90 || lat > 90) {
        setLocationError('Latitude must be between -90 and 90');
        return;
      }

      if (lng < -180 || lng > 180) {
        setLocationError('Longitude must be between -180 and 180');
        return;
      }

      if (radius <= 0) {
        setLocationError('Radius must be greater than 0');
        return;
      }

      const proximitySearchFilters: ProximitySearchFilters = {
        lat,
        lng,
        radius,
      };

      if (proximityFilters.species?.trim()) {
        proximitySearchFilters.species = proximityFilters.species.trim();
      }

      onProximitySearch(proximitySearchFilters);
    } else {
      // Build filters object with only non-empty values
      const activeFilters: SearchFilters = {};
      if (filters.species?.trim()) {
        activeFilters.species = filters.species.trim();
      }
      if (filters.location?.trim()) {
        activeFilters.location = filters.location.trim();
      }
      if (filters.start_date) {
        activeFilters.start_date = new Date(filters.start_date).toISOString();
      }
      if (filters.end_date) {
        activeFilters.end_date = new Date(filters.end_date).toISOString();
      }

      onSearch(activeFilters);
    }
  };

  const handleClear = () => {
    setFilters({
      species: '',
      location: '',
      start_date: '',
      end_date: '',
    });
    setProximityFilters({
      lat: '',
      lng: '',
      radius: '10',
      species: '',
    });
    setProximityMode(false);
    setLocationError(null);
    if (onClear) {
      onClear();
    }
  };

  const handleUseCurrentLocation = async () => {
    setGettingLocation(true);
    setLocationError(null);

    try {
      const coords = await getCurrentPosition();
      setProximityFilters(prev => ({
        ...prev,
        lat: coords.latitude.toFixed(6),
        lng: coords.longitude.toFixed(6),
      }));
      setProximityMode(true);
    } catch (error) {
      if (error instanceof GeolocationError) {
        setLocationError(error.message);
      } else {
        setLocationError('Failed to get current location');
      }
    } finally {
      setGettingLocation(false);
    }
  };

  const handleToggleProximityMode = () => {
    setProximityMode(!proximityMode);
    setLocationError(null);
  };

  const hasActiveFilters = proximityMode
    ? proximityFilters.lat || proximityFilters.lng || proximityFilters.radius || proximityFilters.species?.trim()
    : filters.species?.trim() || filters.location?.trim() || filters.start_date || filters.end_date;

  return (
    <form onSubmit={handleSubmit} className="search-bar">
      {onProximitySearch && (
        <div className="search-mode-toggle">
          <Tooltip content="Switch between standard search (by species, location, date) and proximity search (find observations near a specific location)">
            <button
              type="button"
              onClick={handleToggleProximityMode}
              className={`mode-toggle-btn ${proximityMode ? 'active' : ''}`}
            >
              {proximityMode ? '📍 Proximity Search' : '🔍 Standard Search'}
            </button>
          </Tooltip>
        </div>
      )}

      {proximityMode && onProximitySearch ? (
        <div className="search-bar-fields">
          <div className="proximity-help">
            <p className="help-text">
              🔍 Search for bird observations within a specific distance from any location. Use "Near Me" to search around your current position, or enter coordinates manually.
            </p>
          </div>
          
          <div className="proximity-location-actions">
            <Tooltip content="Automatically use your current GPS location as the search center. Requires location permissions.">
              <button
                type="button"
                onClick={handleUseCurrentLocation}
                disabled={gettingLocation}
                className="near-me-btn"
              >
                {gettingLocation ? '⏳ Getting Location...' : '📍 Near Me'}
              </button>
            </Tooltip>
          </div>

          <div className="search-field">
            <label htmlFor="proximity-lat">
              Latitude
              <Tooltip content="Center latitude for search (-90 to 90). North is positive, South is negative.">
                <span className="info-icon">ℹ️</span>
              </Tooltip>
            </label>
            <input
              type="number"
              id="proximity-lat"
              name="lat"
              value={proximityFilters.lat}
              onChange={handleProximityInputChange}
              placeholder="e.g., 40.7128"
              step="0.000001"
              min="-90"
              max="90"
              required
            />
          </div>

          <div className="search-field">
            <label htmlFor="proximity-lng">
              Longitude
              <Tooltip content="Center longitude for search (-180 to 180). East is positive, West is negative.">
                <span className="info-icon">ℹ️</span>
              </Tooltip>
            </label>
            <input
              type="number"
              id="proximity-lng"
              name="lng"
              value={proximityFilters.lng}
              onChange={handleProximityInputChange}
              placeholder="e.g., -74.0060"
              step="0.000001"
              min="-180"
              max="180"
              required
            />
          </div>

          <div className="search-field">
            <label htmlFor="proximity-radius">
              Radius (km)
              <Tooltip content="Search radius in kilometers. All observations within this distance from the center point will be returned.">
                <span className="info-icon">ℹ️</span>
              </Tooltip>
            </label>
            <input
              type="number"
              id="proximity-radius"
              name="radius"
              value={proximityFilters.radius}
              onChange={handleProximityInputChange}
              placeholder="e.g., 10"
              step="0.1"
              min="0.1"
              required
            />
          </div>

          <div className="search-field">
            <label htmlFor="proximity-species">Species (optional)</label>
            <input
              type="text"
              id="proximity-species"
              name="species"
              value={proximityFilters.species}
              onChange={handleProximityInputChange}
              placeholder="e.g., Robin"
            />
          </div>
        </div>
      ) : (
        <div className="search-bar-fields">
          <div className="search-field">
            <label htmlFor="species">Species</label>
            <input
              type="text"
              id="species"
              name="species"
              value={filters.species}
              onChange={handleInputChange}
              placeholder="e.g., Robin"
            />
          </div>

          <div className="search-field">
            <label htmlFor="location">Location</label>
            <input
              type="text"
              id="location"
              name="location"
              value={filters.location}
              onChange={handleInputChange}
              placeholder="e.g., Central Park"
            />
          </div>

          <div className="search-field">
            <label htmlFor="start_date">From Date</label>
            <input
              type="date"
              id="start_date"
              name="start_date"
              value={filters.start_date}
              onChange={handleInputChange}
              max={new Date().toISOString().split('T')[0]}
            />
          </div>

          <div className="search-field">
            <label htmlFor="end_date">To Date</label>
            <input
              type="date"
              id="end_date"
              name="end_date"
              value={filters.end_date}
              onChange={handleInputChange}
              max={new Date().toISOString().split('T')[0]}
            />
          </div>
        </div>
      )}

      {locationError && (
        <div className="location-error">{locationError}</div>
      )}

      <div className="search-bar-actions">
        <button type="submit" className="search-btn">
          Search
        </button>
        {hasActiveFilters && (
          <button type="button" onClick={handleClear} className="clear-btn">
            Clear
          </button>
        )}
      </div>
    </form>
  );
};

export default SearchBar;
