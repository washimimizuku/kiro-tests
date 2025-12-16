import { describe, it, expect } from 'vitest';
import { MAP_CONFIG } from './mapConfig';

describe('Map Configuration', () => {
  it('should have valid OpenStreetMap tile layer URL', () => {
    expect(MAP_CONFIG.tileLayerUrl).toBe('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png');
  });

  it('should have proper attribution', () => {
    expect(MAP_CONFIG.attribution).toContain('OpenStreetMap');
    expect(MAP_CONFIG.attribution).toContain('contributors');
  });

  it('should have valid default center coordinates', () => {
    const [lat, lng] = MAP_CONFIG.defaultCenter;
    expect(lat).toBeGreaterThanOrEqual(-90);
    expect(lat).toBeLessThanOrEqual(90);
    expect(lng).toBeGreaterThanOrEqual(-180);
    expect(lng).toBeLessThanOrEqual(180);
  });

  it('should have reasonable default zoom level', () => {
    expect(MAP_CONFIG.defaultZoom).toBeGreaterThanOrEqual(MAP_CONFIG.minZoom);
    expect(MAP_CONFIG.defaultZoom).toBeLessThanOrEqual(MAP_CONFIG.maxZoom);
  });

  it('should have valid zoom range', () => {
    expect(MAP_CONFIG.minZoom).toBeGreaterThanOrEqual(0);
    expect(MAP_CONFIG.maxZoom).toBeGreaterThan(MAP_CONFIG.minZoom);
  });

  it('should have detail zoom greater than default zoom', () => {
    expect(MAP_CONFIG.detailZoom).toBeGreaterThan(MAP_CONFIG.defaultZoom);
  });

  it('should have positive cluster threshold', () => {
    expect(MAP_CONFIG.clusterThreshold).toBeGreaterThan(0);
  });
});
