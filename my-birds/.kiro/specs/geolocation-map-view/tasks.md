# Implementation Plan

- [x] 1. Database schema updates for coordinates
- [x] 1.1 Create migration to add latitude and longitude columns
  - Add nullable DECIMAL(10, 8) latitude column to observations table
  - Add nullable DECIMAL(11, 8) longitude column to observations table
  - Create index on latitude and longitude for proximity searches
  - _Requirements: 1.1, 1.2_

- [x] 1.2 Test migration rollback and forward
  - Verify migration applies cleanly
  - Verify existing observations remain intact with null coordinates
  - _Requirements: 1.1, 1.2_

- [x] 2. Backend coordinate validation and storage
- [x] 2.1 Update Observation model with coordinate fields
  - Add latitude: Option<f64> field
  - Add longitude: Option<f64> field
  - Update serialization/deserialization
  - _Requirements: 1.1, 1.2_

- [x] 2.2 Implement coordinate validation service
  - Create CoordinateValidator with latitude bounds check (-90 to 90)
  - Add longitude bounds check (-180 to 180)
  - Add coordinate pair validation (both or neither)
  - Add numeric validation
  - _Requirements: 1.4, 1.5, 9.1, 9.2, 9.3, 9.4_

- [x] 2.3 Update observation repository for coordinates
  - Modify create query to include latitude/longitude
  - Modify update query to handle coordinate changes
  - Modify select queries to return coordinates
  - _Requirements: 1.1, 1.3_

- [x] 2.4 Update observation API endpoints
  - Update CreateObservationRequest to include optional coordinates
  - Update UpdateObservationRequest to include optional coordinates
  - Add validation to POST /api/observations endpoint
  - Add validation to PUT /api/observations/:id endpoint
  - _Requirements: 1.1, 1.3, 9.1, 9.2, 9.3, 9.4_

- [x] 2.5 Write property test for coordinate storage
  - **Property 1: Coordinate storage persistence**
  - **Validates: Requirements 1.1**

- [x] 2.6 Write property test for optional coordinates
  - **Property 2: Optional coordinates acceptance**
  - **Validates: Requirements 1.2**

- [x] 2.7 Write property test for coordinate updates
  - **Property 3: Coordinate update persistence**
  - **Validates: Requirements 1.3**

- [x] 2.8 Write property test for latitude validation
  - **Property 4: Latitude bounds validation**
  - **Validates: Requirements 1.4, 9.1**

- [x] 2.9 Write property test for longitude validation
  - **Property 5: Longitude bounds validation**
  - **Validates: Requirements 1.5, 9.2**

- [x] 2.10 Write property test for coordinate pair requirement
  - **Property 6: Coordinate pair requirement**
  - **Validates: Requirements 9.3**

- [x] 2.11 Write property test for numeric validation
  - **Property 7: Numeric coordinate validation**
  - **Validates: Requirements 9.4**

- [x] 3. Implement Haversine distance calculation
- [x] 3.1 Create GeoService with Haversine formula
  - Implement haversine_distance function
  - Handle edge cases (poles, date line crossing)
  - Return distance in kilometers
  - _Requirements: 8.2_

- [x] 3.2 Write property test for Haversine accuracy
  - **Property 15: Haversine distance calculation**
  - **Validates: Requirements 8.2**

- [x] 3.3 Write unit tests for known coordinate pairs
  - Test distance between New York and London
  - Test distance between Sydney and Tokyo
  - Test distance at equator vs poles
  - _Requirements: 8.2_

- [x] 4. Implement proximity search
- [x] 4.1 Create proximity search repository method
  - Implement query to find observations within radius
  - Use Haversine formula for distance calculation
  - Support optional filters (user_id, species)
  - Return observations with distance field
  - _Requirements: 8.1, 8.3_

- [x] 4.2 Create proximity search API endpoint
  - Add GET /api/observations/nearby endpoint
  - Parse lat, lng, radius query parameters
  - Validate search parameters
  - Return observations with distances
  - _Requirements: 8.1, 8.3_

- [x] 4.3 Write property test for proximity search radius
  - **Property 14: Proximity search radius correctness**
  - **Validates: Requirements 8.1**

- [x] 4.4 Write property test for distance inclusion
  - **Property 16: Distance inclusion in results**
  - **Validates: Requirements 8.3**

- [x] 5. Checkpoint - Backend tests
  - Ensure all backend tests pass, ask the user if questions arise.

- [x] 6. Frontend coordinate utilities
- [x] 6.1 Create coordinate formatting utilities
  - Implement formatCoordinate with 6 decimal precision
  - Implement formatCoordinateWithDirection (N/S/E/W)
  - Implement formatForGPS
  - Implement validation functions (isValidLatitude, isValidLongitude)
  - _Requirements: 2.5, 7.1, 7.2, 7.4_

- [x] 6.2 Write unit tests for coordinate formatting
  - Test precision formatting
  - Test directional formatting for all quadrants
  - Test GPS format output
  - Test validation functions
  - _Requirements: 2.5, 7.1, 7.2, 7.4_

- [x] 6.3 Create coordinate filtering utilities
  - Implement function to filter observations with coordinates
  - Implement function to filter shared observations with coordinates
  - Implement function to filter trip observations with coordinates
  - _Requirements: 3.3, 5.1, 6.1_

- [x] 6.4 Write property tests for filtering
  - **Property 11: Coordinate filtering for map display**
  - **Property 12: Shared observations with coordinates**
  - **Property 13: Trip observations with coordinates**
  - **Validates: Requirements 3.3, 5.1, 6.1**

- [x] 7. Geolocation service
- [x] 7.1 Create geolocation service
  - Implement getCurrentPosition using browser API
  - Implement isSupported check
  - Handle permission denied errors
  - Handle position unavailable errors
  - Handle timeout errors
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 7.2 Write unit tests for geolocation service
  - Test with mocked browser geolocation API
  - Test error handling for each error type
  - Test permission checks
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 8. Install and configure map library
- [x] 8.1 Add Leaflet dependencies
  - Install leaflet package
  - Install react-leaflet package
  - Install react-leaflet-cluster package
  - Install @types/leaflet
  - Add Leaflet CSS to index.html
  - _Requirements: 3.1_

- [x] 8.2 Configure map tile provider
  - Set up OpenStreetMap tile layer
  - Configure attribution
  - Set default zoom and center
  - _Requirements: 3.1_

- [x] 9. Create map components
- [x] 9.1 Create ObservationMap component
  - Display Leaflet map with observations as markers
  - Support marker clustering for performance
  - Show popup with observation details on marker click
  - Support custom center and zoom props
  - Handle empty observation list
  - _Requirements: 3.1, 3.2, 3.3, 10.1_

- [x] 9.2 Create LocationPicker component
  - Display interactive map for coordinate selection
  - Support clicking map to set coordinates
  - Display draggable marker at selected location
  - Include "Use Current Location" button
  - Include "Clear Location" button
  - Show coordinate values below map
  - _Requirements: 2.1, 4.1, 4.2, 4.3, 4.5_

- [x] 9.3 Write unit tests for map components
  - Test ObservationMap renders with observations
  - Test LocationPicker coordinate updates
  - Test marker clustering activation
  - _Requirements: 3.1, 4.1_

- [x] 10. Update observation form with coordinates
- [x] 10.1 Add coordinate fields to ObservationForm
  - Add LocationPicker component to form
  - Add latitude and longitude display fields
  - Integrate "Use Current Location" functionality
  - Add coordinate validation
  - Update form submission to include coordinates
  - _Requirements: 1.1, 2.1, 2.2, 4.1_

- [x] 10.2 Update API service for coordinates
  - Update createObservation to send coordinates
  - Update updateObservation to send coordinates
  - Handle coordinate validation errors from API
  - _Requirements: 1.1, 1.3_

- [x] 11. Add map views to existing pages
- [x] 11.1 Add map to ObservationsPage
  - Add toggle between list and map view
  - Display ObservationMap with user's observations
  - Filter observations to only those with coordinates
  - Center map on observations
  - _Requirements: 3.1, 3.3_

- [x] 11.2 Add map to ObservationDetailPage
  - Display small map if observation has coordinates
  - Center map on observation location
  - Show single marker for observation
  - Display formatted coordinates below map
  - Show "Location not specified" if no coordinates
  - _Requirements: 3.4, 7.1, 7.5_

- [x] 11.3 Add map to TripDetailPage
  - Display map showing all trip observations with coordinates
  - Filter trip observations to only those with coordinates
  - Center and zoom to fit all markers
  - Show message if no observations have coordinates
  - _Requirements: 6.1, 6.3, 6.4, 6.5_

- [x] 11.4 Add map to SharedObservationsPage
  - Display map with all shared observations that have coordinates
  - Filter shared observations to only those with coordinates
  - Update map when filters are applied
  - Center and zoom to fit all markers
  - _Requirements: 5.1, 5.3, 5.5_

- [x] 12. Implement proximity search UI
- [x] 12.1 Add proximity search to SearchBar
  - Add "Near Me" button to use current location
  - Add radius input field (in kilometers)
  - Add coordinate input fields for custom center
  - Update search to call proximity endpoint when coordinates provided
  - Display distance in search results
  - _Requirements: 8.1, 8.3, 8.4_

- [x] 12.2 Update observation list to show distances
  - Display distance from search center in observation cards
  - Sort results by distance when proximity search is active
  - _Requirements: 8.3_

- [x] 13. Add coordinate display to observation cards
- [x] 13.1 Update ObservationCard component
  - Display formatted coordinates if present
  - Add link to view on external map (Google Maps)
  - Show location icon for observations with coordinates
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 13.2 Add coordinate copying functionality
  - Add "Copy Coordinates" button
  - Format coordinates for GPS devices
  - Show success message after copying
  - _Requirements: 7.4_

- [x] 14. Performance optimizations
- [x] 14.1 Implement marker clustering
  - Configure react-leaflet-cluster
  - Set clustering threshold to 100 markers
  - Customize cluster appearance
  - _Requirements: 10.1_

- [x] 14.2 Add lazy loading for map components
  - Use React.lazy for map components
  - Show loading indicator while map loads
  - Defer map loading until component is visible
  - _Requirements: 10.3, 10.5_

- [x] 14.3 Add error handling for map tiles
  - Handle tile load failures
  - Display error message
  - Implement retry logic
  - _Requirements: 10.4_

- [x] 15. Update types and interfaces
- [x] 15.1 Update TypeScript types
  - Add latitude and longitude to Observation interface
  - Add ObservationWithDistance interface
  - Add ProximitySearchParams interface
  - Add GeolocationError types
  - _Requirements: All_

- [x] 15.2 Update API service types
  - Update observation API functions with coordinate types
  - Add proximity search API function
  - _Requirements: All_

- [x] 16. Add CSS styling for map components
- [x] 16.1 Style ObservationMap component
  - Set appropriate height and width
  - Style marker popups
  - Style cluster markers
  - Add responsive design
  - _Requirements: 3.1_

- [x] 16.2 Style LocationPicker component
  - Set map height for form context
  - Style coordinate display
  - Style action buttons
  - Add responsive design
  - _Requirements: 4.1_

- [x] 17. Documentation and user guidance
- [x] 17.1 Add tooltips and help text
  - Add tooltip explaining coordinate fields
  - Add help text for "Use Current Location" button
  - Add explanation of proximity search
  - _Requirements: 2.1, 8.1_

- [x] 17.2 Update README with geolocation features
  - Document new coordinate fields
  - Document proximity search API
  - Document map components
  - _Requirements: All_

- [x] 18. Final checkpoint - Integration testing
  - Test complete flow: create observation with coordinates
  - Test map views on all pages
  - Test proximity search
  - Test coordinate validation
  - Ensure all tests pass, ask the user if questions arise.
