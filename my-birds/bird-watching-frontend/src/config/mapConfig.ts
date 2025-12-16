/**
 * Map configuration for Leaflet
 * Defines default settings for map tiles, attribution, and initial view
 */

export const MAP_CONFIG = {
  // OpenStreetMap tile layer URL
  tileLayerUrl: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  
  // Attribution text (required by OpenStreetMap)
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  
  // Default center coordinates (US center)
  defaultCenter: [39.8283, -98.5795] as [number, number],
  
  // Default zoom level
  defaultZoom: 4,
  
  // Zoom level for single observation view
  detailZoom: 13,
  
  // Maximum zoom level
  maxZoom: 19,
  
  // Minimum zoom level
  minZoom: 2,
  
  // Marker clustering threshold
  clusterThreshold: 100,
} as const;

export type MapConfig = typeof MAP_CONFIG;
