# Implementation Plan

- [x] 1. Set up project structure and dependencies
  - Create Rust backend project with Cargo
  - Create React frontend project with TypeScript
  - Configure database connection and migrations
  - Set up testing frameworks (proptest for backend, Jest for frontend)
  - _Requirements: All_

- [x] 2. Implement database schema and migrations
  - Create PostgreSQL migration files for users, observations, and trips tables
  - Add indexes on frequently queried fields
  - Set up database connection pool
  - _Requirements: 6.1_

- [x] 3. Implement User model and authentication
- [x] 3.1 Create User model and database repository
  - Define User struct with all fields
  - Implement UserRepository with CRUD operations
  - _Requirements: 1.1, 1.5_

- [x] 3.2 Implement password hashing and validation
  - Use bcrypt for password hashing
  - Implement password verification
  - _Requirements: 1.1, 1.3_

- [x] 3.3 Implement JWT token generation and validation
  - Create JWT token with user claims
  - Implement token validation middleware
  - _Requirements: 1.3, 7.3_

- [x] 3.4 Create authentication API endpoints
  - POST /api/auth/register endpoint
  - POST /api/auth/login endpoint
  - GET /api/users/me endpoint
  - _Requirements: 1.1, 1.3, 1.5_

- [x] 3.5 Write property test for user registration
  - **Property 1: Valid registration creates unique user**
  - **Validates: Requirements 1.1**

- [x] 3.6 Write property test for duplicate registration
  - **Property 2: Duplicate registration rejection**
  - **Validates: Requirements 1.2**

- [x] 3.7 Write property test for authentication
  - **Property 3: Valid authentication returns token**
  - **Validates: Requirements 1.3**

- [x] 3.8 Write property test for invalid credentials
  - **Property 4: Invalid credentials rejection**
  - **Validates: Requirements 1.4**

- [x] 3.9 Write property test for profile password exclusion
  - **Property 5: Profile excludes password**
  - **Validates: Requirements 1.5**

- [x] 4. Implement Observation model and CRUD operations
- [x] 4.1 Create Observation model and repository
  - Define Observation struct with all fields
  - Implement ObservationRepository with CRUD operations
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 4.2 Create observation API endpoints
  - POST /api/observations endpoint
  - GET /api/observations endpoint (user's observations)
  - GET /api/observations/:id endpoint
  - PUT /api/observations/:id endpoint
  - DELETE /api/observations/:id endpoint
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 4.3 Implement authorization checks for observations
  - Verify user owns observation before update/delete
  - Extract user ID from JWT token
  - _Requirements: 2.5_

- [x] 4.4 Write property test for observation creation
  - **Property 6: Observation creation with user association**
  - **Validates: Requirements 2.1, 2.2**

- [x] 4.5 Write property test for observation isolation
  - **Property 7: User observation isolation**
  - **Validates: Requirements 2.3**

- [x] 4.6 Write property test for observation updates
  - **Property 8: Observation update persistence**
  - **Validates: Requirements 2.4**

- [x] 4.7 Write property test for unauthorized updates
  - **Property 9: Unauthorized update rejection**
  - **Validates: Requirements 2.5**

- [x] 5. Implement photo upload and management
- [x] 5.1 Create photo storage service
  - Implement file upload handling
  - Store photos in filesystem or S3-compatible storage
  - Generate unique filenames
  - _Requirements: 3.1_

- [x] 5.2 Create photo upload endpoint
  - POST /api/photos/upload endpoint
  - Validate file type and size
  - Return photo URL
  - _Requirements: 3.1, 3.5_

- [x] 5.3 Integrate photo URLs with observations
  - Add photo_url field handling in observation endpoints
  - Support optional photo in observation creation
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 5.4 Implement photo deletion on observation delete
  - Delete photo file when observation is deleted
  - Handle missing photo files gracefully
  - _Requirements: 3.4_

- [x] 5.5 Write property test for photo storage
  - **Property 10: Photo storage and association**
  - **Validates: Requirements 3.1**

- [x] 5.6 Write property test for photo in response
  - **Property 11: Photo reference in response**
  - **Validates: Requirements 3.3**

- [x] 5.7 Write property test for cascading deletion
  - **Property 12: Cascading photo deletion**
  - **Validates: Requirements 3.4**

- [x] 5.8 Write property test for file type validation
  - **Property 13: Photo file type validation**
  - **Validates: Requirements 3.5**

- [x] 6. Implement Trip model and operations
- [x] 6.1 Create Trip model and repository
  - Define Trip struct with all fields
  - Implement TripRepository with CRUD operations
  - _Requirements: 4.1_

- [x] 6.2 Create trip API endpoints
  - POST /api/trips endpoint
  - GET /api/trips endpoint (user's trips)
  - GET /api/trips/:id endpoint (with observations)
  - PUT /api/trips/:id endpoint
  - DELETE /api/trips/:id endpoint
  - _Requirements: 4.1, 4.3, 4.4, 4.5_

- [x] 6.3 Implement observation-trip association
  - Support trip_id in observation creation/update
  - Validate trip belongs to user
  - _Requirements: 4.2_

- [x] 6.4 Implement trip deletion logic
  - Set observations' trip_id to null when trip is deleted
  - Preserve observations
  - _Requirements: 4.4_

- [x] 6.5 Write property test for trip creation
  - **Property 14: Trip creation**
  - **Validates: Requirements 4.1**

- [x] 6.6 Write property test for observation-trip association
  - **Property 15: Observation-trip association**
  - **Validates: Requirements 4.2**

- [x] 6.7 Write property test for trip details
  - **Property 16: Trip details completeness**
  - **Validates: Requirements 4.3**

- [x] 6.8 Write property test for trip deletion
  - **Property 17: Trip deletion preserves observations**
  - **Validates: Requirements 4.4**

- [x] 6.9 Write property test for trip updates
  - **Property 18: Trip update preserves associations**
  - **Validates: Requirements 4.5**

- [x] 7. Implement observation sharing functionality
- [x] 7.1 Add sharing logic to observation endpoints
  - Support is_shared field in observation creation/update
  - Default to private (is_shared = false)
  - _Requirements: 5.1, 5.2_

- [x] 7.2 Create shared observations endpoint
  - GET /api/observations/shared endpoint
  - Return all shared observations with owner username
  - _Requirements: 5.3, 5.4_

- [x] 7.3 Implement authorization for shared observations
  - Allow viewing shared observations by any authenticated user
  - Prevent modification by non-owners
  - _Requirements: 5.5_

- [x] 7.4 Write property test for shared visibility
  - **Property 19: Shared observation visibility**
  - **Validates: Requirements 5.1**

- [x] 7.5 Write property test for private restriction
  - **Property 20: Private observation restriction**
  - **Validates: Requirements 5.2**

- [x] 7.6 Write property test for shared query
  - **Property 21: Shared observations query correctness**
  - **Validates: Requirements 5.3**

- [x] 7.7 Write property test for owner inclusion
  - **Property 22: Shared observation includes owner**
  - **Validates: Requirements 5.4**

- [x] 7.8 Write property test for shared modification restriction
  - **Property 23: Shared observation modification restriction**
  - **Validates: Requirements 5.5**

- [x] 8. Implement search and filtering
- [x] 8.1 Create search endpoint with query parameters
  - GET /api/observations/search endpoint
  - Support species, location, start_date, end_date parameters
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 8.2 Implement search query logic
  - Build dynamic SQL queries based on provided filters
  - Handle case-insensitive matching
  - Support multiple simultaneous filters
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 8.3 Write property test for species search
  - **Property 29: Species name search**
  - **Validates: Requirements 9.1**

- [x] 8.4 Write property test for date filtering
  - **Property 30: Date range filtering**
  - **Validates: Requirements 9.2**

- [x] 8.5 Write property test for location filtering
  - **Property 31: Location filtering**
  - **Validates: Requirements 9.3**

- [x] 8.6 Write property test for multiple filters
  - **Property 32: Multiple filter conjunction**
  - **Validates: Requirements 9.4**

- [x] 9. Implement comprehensive input validation
- [x] 9.1 Add validation to all API endpoints
  - Validate required fields are present
  - Validate data formats (email, dates, UUIDs)
  - Validate text length constraints
  - Validate business rules (no future dates for observations)
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 9.2 Create consistent error responses
  - Return 400 for validation errors
  - Include field names and error details
  - _Requirements: 7.4, 10.1_

- [x] 9.3 Write property test for missing fields
  - **Property 33: Missing required fields rejection**
  - **Validates: Requirements 10.1**

- [x] 9.4 Write property test for invalid formats
  - **Property 34: Invalid format rejection**
  - **Validates: Requirements 10.2**

- [x] 9.5 Write property test for future dates
  - **Property 35: Future date rejection**
  - **Validates: Requirements 10.3**

- [x] 9.6 Write property test for text length
  - **Property 36: Text length validation**
  - **Validates: Requirements 10.4**

- [x] 10. Implement API-level properties
- [x] 10.1 Write property test for HTTP responses
  - **Property 25: HTTP response correctness**
  - **Validates: Requirements 7.1, 7.4**

- [x] 10.2 Write property test for JSON format
  - **Property 26: JSON response format**
  - **Validates: Requirements 7.2**

- [x] 10.3 Write property test for authentication enforcement
  - **Property 27: Authentication enforcement**
  - **Validates: Requirements 7.3**

- [x] 10.4 Write property test for invalid JSON
  - **Property 28: Invalid JSON rejection**
  - **Validates: Requirements 7.5**

- [x] 10.5 Write property test for immediate persistence
  - **Property 24: Immediate persistence**
  - **Validates: Requirements 6.1**

- [x] 11. Checkpoint - Ensure all backend tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Set up React frontend project
- [x] 12.1 Initialize React app with TypeScript
  - Create React app with TypeScript template
  - Set up project structure (pages, components, services)
  - Configure routing with React Router
  - _Requirements: 8.1_

- [x] 12.2 Create API service layer
  - Set up Axios instance with base URL
  - Implement request interceptor for JWT token injection
  - Implement response interceptor for error handling
  - _Requirements: 7.2, 7.3_

- [x] 12.3 Implement authentication service
  - Create login and register API functions
  - Implement token storage in localStorage
  - Create auth context for user state management
  - _Requirements: 1.1, 1.3_

- [x] 13. Implement authentication UI
- [x] 13.1 Create Login page
  - Build login form with username and password fields
  - Handle form submission and errors
  - Redirect to dashboard on success
  - _Requirements: 1.3, 8.1_

- [x] 13.2 Create Register page
  - Build registration form with username, email, password fields
  - Handle form validation and submission
  - Redirect to login on success
  - _Requirements: 1.1, 8.1_

- [x] 13.3 Create ProtectedRoute component
  - Check authentication status
  - Redirect to login if not authenticated
  - _Requirements: 7.3_

- [x] 14. Implement observation UI
- [x] 14.1 Create ObservationForm component
  - Build form with species, date, location, notes, photo fields
  - Implement photo upload with preview
  - Handle form submission
  - _Requirements: 2.1, 3.1, 8.3, 8.4_

- [x] 14.2 Create ObservationCard component
  - Display observation details
  - Show photo if present
  - Include edit and delete buttons for owned observations
  - _Requirements: 2.3, 3.3_

- [x] 14.3 Create ObservationsPage
  - List user's observations
  - Include button to create new observation
  - Implement edit and delete functionality
  - _Requirements: 2.3, 2.4, 8.2_

- [x] 14.4 Create ObservationDetailPage
  - Display full observation details
  - Show associated trip if present
  - Allow editing if user owns observation
  - _Requirements: 2.3, 4.2_

- [x] 15. Implement trip UI
- [x] 15.1 Create TripForm component
  - Build form with name, date, location, description fields
  - Handle form submission
  - _Requirements: 4.1_

- [x] 15.2 Create TripCard component
  - Display trip summary
  - Show observation count
  - Include edit and delete buttons
  - _Requirements: 4.3_

- [x] 15.3 Create TripsPage
  - List user's trips
  - Include button to create new trip
  - Implement edit and delete functionality
  - _Requirements: 4.1, 4.3_

- [x] 15.4 Create TripDetailPage
  - Display trip details
  - List all observations in trip
  - Allow adding existing observations to trip
  - _Requirements: 4.2, 4.3_

- [x] 16. Implement sharing and search UI
- [x] 16.1 Add sharing toggle to ObservationForm
  - Include checkbox for is_shared field
  - Show sharing status on observation cards
  - _Requirements: 5.1, 5.2_

- [x] 16.2 Create SharedObservationsPage
  - Display all shared observations from all users
  - Show owner username for each observation
  - Implement browsable grid or list layout
  - _Requirements: 5.3, 5.4, 8.5_

- [x] 16.3 Create SearchBar component
  - Build search form with species, location, date range filters
  - Handle filter changes and submission
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 16.4 Integrate search into ObservationsPage
  - Add SearchBar component
  - Update observation list based on search results
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 17. Implement Dashboard page
- [x] 17.1 Create Dashboard component
  - Display recent observations
  - Display recent trips
  - Show summary statistics (total observations, species count)
  - _Requirements: 8.2_

- [x] 17.2 Add navigation menu
  - Create navigation bar with links to all pages
  - Include logout functionality
  - _Requirements: 8.1_

- [x] 18. Add error handling and loading states
- [x] 18.1 Implement global error handling
  - Create error boundary component
  - Display user-friendly error messages
  - _Requirements: 7.4_

- [x] 18.2 Add loading indicators
  - Show spinners during API calls
  - Disable forms during submission
  - _Requirements: 8.2_

- [x] 19. Final checkpoint - Integration testing
  - Ensure all tests pass, ask the user if questions arise.
