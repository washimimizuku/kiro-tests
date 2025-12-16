# Implementation Plan

- [x] 1. Project setup and configuration
- [x] 1.1 Create Flutter project
  - Initialize new Flutter project with appropriate bundle ID
  - Configure project for iOS and Android
  - Set minimum SDK versions (iOS 13.0, Android 21)
  - _Requirements: All_

- [x] 1.2 Add dependencies to pubspec.yaml
  - Add flutter_bloc, dio, sqflite, flutter_secure_storage
  - Add geolocator, google_maps_flutter, image_picker
  - Add connectivity_plus, cached_network_image
  - Add testing dependencies (mockito, flutter_test)
  - _Requirements: All_

- [x] 1.3 Configure platform-specific permissions
  - Add camera, location, storage permissions to iOS Info.plist
  - Add camera, location, storage permissions to Android AndroidManifest.xml
  - Configure Google Maps API keys for both platforms
  - _Requirements: 3.1, 4.1_

- [x] 1.4 Set up project structure
  - Create folder structure (core, data, domain, presentation)
  - Create constants file for API base URL and app config
  - Set up dependency injection container
  - _Requirements: All_

- [x] 2. Core utilities and services
- [x] 2.1 Create API service
  - Implement Dio HTTP client with base URL configuration
  - Add request/response interceptors for logging
  - Add authentication token interceptor
  - Implement error handling and retry logic
  - _Requirements: 1.2, 20.2_

- [x] 2.2 Create secure storage service
  - Implement FlutterSecureStorage wrapper
  - Add methods for token storage and retrieval
  - Add method to clear all secure data
  - _Requirements: 1.2, 20.1_

- [x] 2.3 Create local database service
  - Set up SQLite database with sqflite
  - Create observations table schema
  - Create trips table schema
  - Implement database migration logic
  - _Requirements: 5.2, 6.1_

- [x] 2.4 Create connectivity service
  - Implement connectivity monitoring with connectivity_plus
  - Add stream for connectivity changes
  - Add method to check internet access
  - _Requirements: 5.1, 17.4_

- [x] 2.5 Create GPS service
  - Implement geolocator wrapper
  - Add method to get current position
  - Add permission checking and requesting
  - Handle location service disabled scenarios
  - _Requirements: 4.1, 4.2, 4.4_

- [x] 2.6 Create camera service
  - Implement image_picker wrapper
  - Add method to take photo with camera
  - Add method to pick photo from gallery
  - Check camera availability
  - _Requirements: 3.1, 3.5_

- [x] 3. Data models
- [x] 3.1 Create User model
  - Define User class with all fields
  - Implement JSON serialization (fromJson, toJson)
  - Add copyWith method
  - _Requirements: 1.1_

- [x] 3.2 Create Observation model
  - Define Observation class with all fields including coordinates
  - Add pendingSync and localPhotoPath fields for offline support
  - Implement JSON serialization
  - Implement SQLite serialization (toMap, fromMap)
  - Add copyWith method
  - _Requirements: 2.1, 4.2, 5.2_

- [x] 3.3 Create Trip model
  - Define Trip class with all fields
  - Implement JSON serialization
  - Implement SQLite serialization
  - Add copyWith method
  - _Requirements: 9.1_

- [x] 3.4 Create SyncResult model
  - Define SyncResult class for sync operation results
  - Include success/failure counts and error messages
  - _Requirements: 5.3, 5.4_

- [x] 4. Repositories
- [x] 4.1 Implement AuthRepository
  - Create login method calling backend API
  - Create register method calling backend API
  - Implement token storage using secure storage
  - Implement logout with credential clearing
  - Add getCurrentUser method
  - _Requirements: 1.2, 1.5, 2.2, 2.3, 2.4_

- [x] 4.2 Write property test for login token storage
  - **Property 1: Valid login stores token**
  - **Validates: Requirements 1.2**

- [x] 4.3 Write property test for logout
  - **Property 2: Logout clears credentials**
  - **Validates: Requirements 1.5, 13.5, 20.5**

- [x] 4.4 Write property test for registration
  - **Property 3: Registration creates account**
  - **Validates: Requirements 2.2, 2.3**

- [x] 4.5 Write property test for duplicate registration
  - **Property 4: Duplicate registration rejection**
  - **Validates: Requirements 2.4**

- [x] 4.6 Implement ObservationRepository
  - Create getObservations method (API + local cache)
  - Create createObservation method (online/offline)
  - Create updateObservation method
  - Create deleteObservation method
  - Implement getPendingSyncObservations method
  - Implement syncObservation method
  - Add search and filter methods
  - _Requirements: 5.1, 5.2, 6.1, 7.2, 7.3, 11.1, 11.2_

- [x] 4.7 Write property test for offline observation creation
  - **Property 9: Offline observation creation**
  - **Validates: Requirements 5.1, 5.2**

- [x] 4.8 Write property test for observation CRUD
  - **Property 14: Observation creation persistence**
  - **Property 15: Observation update persistence**
  - **Validates: Requirements 7.2, 7.3**

- [x] 4.9 Write property test for unauthorized edits
  - **Property 16: Unauthorized edit rejection**
  - **Validates: Requirements 7.4**

- [x] 4.10 Implement TripRepository
  - Create getTrips method
  - Create createTrip method
  - Create updateTrip method
  - Create deleteTrip method
  - Create getTripObservations method
  - _Requirements: 9.1, 9.2, 9.3, 9.5_

- [x] 4.11 Write property test for trip operations
  - **Property 17: Trip creation persistence**
  - **Property 18: Trip-observation association**
  - **Property 19: Trip deletion preserves observations**
  - **Validates: Requirements 9.2, 9.3, 9.4, 9.5**

- [x] 4.12 Implement PhotoRepository
  - Create uploadPhoto method
  - Implement photo compression with flutter_image_compress
  - Implement photo caching
  - Add getCachedPhoto method
  - Add clearPhotoCache method
  - Add getCacheSize method
  - _Requirements: 3.3, 3.4, 12.5, 14.1, 14.2_

- [x] 4.13 Write property test for photo compression
  - **Property 5: Photo compression reduces size**
  - **Validates: Requirements 3.3**

- [x] 4.14 Write property test for photo upload
  - **Property 6: Observation with photo uploads successfully**
  - **Validates: Requirements 3.4**

- [x] 4.15 Write property test for cached photos
  - **Property 26: Cached photo offline access**
  - **Validates: Requirements 12.5**

- [x] 5. Sync service implementation
- [x] 5.1 Create SyncService
  - Implement syncPendingObservations method
  - Add connectivity monitoring
  - Implement exponential backoff retry logic
  - Add sync progress stream
  - Implement auto-sync on connectivity restore
  - Prioritize observations with photos
  - _Requirements: 5.3, 5.4, 14.4_

- [x] 5.2 Write property test for auto-sync
  - **Property 10: Automatic sync on connectivity**
  - **Validates: Requirements 5.3**

- [x] 5.3 Write property test for retry logic
  - **Property 11: Sync retry with exponential backoff**
  - **Validates: Requirements 5.4**

- [x] 5.4 Write property test for sync prioritization
  - **Property 31: Sync prioritizes photos**
  - **Validates: Requirements 14.4**

- [x] 6. BLoC state management
- [x] 6.1 Create AuthBloc
  - Define AuthState classes (Initial, Loading, Authenticated, Unauthenticated, Error)
  - Define AuthEvent classes (LoginRequested, RegisterRequested, LogoutRequested, TokenExpired)
  - Implement event handlers
  - Add token expiration handling
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3_

- [x] 6.2 Create ObservationBloc
  - Define ObservationState classes
  - Define ObservationEvent classes
  - Implement CRUD event handlers
  - Add offline mode handling
  - Add sync status tracking
  - _Requirements: 5.1, 5.2, 6.1, 7.1, 7.2, 7.3_

- [x] 6.3 Create TripBloc
  - Define TripState classes
  - Define TripEvent classes
  - Implement CRUD event handlers
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 6.4 Create SyncBloc
  - Define SyncState classes (Idle, Syncing, Complete, Error)
  - Define SyncEvent classes
  - Implement sync coordination
  - Add progress tracking
  - _Requirements: 5.3, 5.4, 15.1, 15.2_

- [x] 6.5 Create MapBloc
  - Define MapState classes
  - Define MapEvent classes
  - Implement marker management
  - Add clustering logic
  - _Requirements: 8.1, 8.4_

- [x] 6.6 Write unit tests for BLoCs
  - Test AuthBloc state transitions
  - Test ObservationBloc offline handling
  - Test SyncBloc retry logic
  - _Requirements: All BLoC requirements_

- [x] 7. Authentication screens
- [x] 7.1 Create LoginScreen
  - Build login form with username and password fields
  - Add password visibility toggle
  - Add "Remember me" checkbox
  - Implement form validation
  - Connect to AuthBloc
  - Handle loading and error states
  - Navigate to home on success
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 7.2 Create RegisterScreen
  - Build registration form with username, email, password fields
  - Add password confirmation field
  - Implement form validation
  - Connect to AuthBloc
  - Handle loading and error states
  - Auto-login on successful registration
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 7.3 Write widget tests for auth screens
  - Test login form validation
  - Test registration form validation
  - Test error display
  - _Requirements: 1.1, 2.1_

- [x] 8. Home and navigation
- [x] 8.1 Create HomeScreen with bottom navigation
  - Implement bottom navigation bar
  - Add tabs: Observations, Map, Trips, Community, Profile
  - Add FAB for quick observation creation
  - Add sync status banner
  - _Requirements: 6.1, 8.1, 9.1, 10.1_

- [x] 8.2 Implement navigation routing
  - Set up named routes
  - Implement route guards for authentication
  - Add navigation transitions
  - _Requirements: All navigation_

- [x] 9. Observation screens
- [x] 9.1 Create ObservationsScreen
  - Display observation list with thumbnails
  - Implement pull-to-refresh
  - Add search bar
  - Add filter options (date range, species)
  - Show sync status indicators
  - Implement pagination
  - _Requirements: 6.1, 6.3, 6.4, 11.1, 11.2, 16.2_

- [x] 9.2 Write property test for observation ordering
  - **Property 12: Observations chronological order**
  - **Validates: Requirements 6.1**

- [x] 9.3 Write property test for search filtering
  - **Property 21: Search filter correctness**
  - **Validates: Requirements 10.3, 11.1**

- [x] 9.4 Write property test for date filtering
  - **Property 22: Date range filter correctness**
  - **Validates: Requirements 11.2**

- [x] 9.5 Write property test for filter clearing
  - **Property 23: Filter clearing returns all results**
  - **Validates: Requirements 11.3**

- [x] 9.6 Write property test for pagination
  - **Property 25: Pagination page size**
  - **Validates: Requirements 10.5**

- [x] 9.7 Create ObservationDetailScreen
  - Display full observation details
  - Show photo in full resolution
  - Display map with observation location
  - Add edit and delete buttons (if owner)
  - Show formatted coordinates
  - _Requirements: 6.2, 8.3, 12.1_

- [x] 9.8 Create ObservationFormScreen
  - Build form with all observation fields
  - Integrate PhotoPicker widget
  - Integrate LocationPicker widget
  - Auto-capture GPS coordinates
  - Add date picker (default: today)
  - Add trip selector
  - Add share toggle
  - Implement form validation
  - Handle offline creation
  - _Requirements: 3.1, 4.1, 4.2, 7.1, 7.2, 18.1, 18.2, 18.3_

- [x] 9.9 Write property test for validation
  - **Property 8: Coordinate validation**
  - **Property 34: Future date rejection**
  - **Property 35: Text length validation**
  - **Validates: Requirements 18.2, 18.3, 18.4**

- [x] 10. Reusable observation widgets
- [x] 10.1 Create ObservationCard widget
  - Display thumbnail image
  - Show species name, date, location
  - Add sync status indicator
  - Make tappable for navigation
  - _Requirements: 6.3_

- [x] 10.2 Create PhotoPicker widget
  - Add camera button
  - Add gallery button
  - Show photo preview
  - Display compression progress
  - Handle camera unavailable scenario
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

- [x] 10.3 Create LocationPicker widget
  - Display interactive map
  - Add "Use Current Location" button
  - Show coordinate display with accuracy
  - Allow map click to set coordinates
  - Add draggable marker
  - Show GPS accuracy warning if low
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [x] 10.4 Write property test for GPS coordinates
  - **Property 7: GPS coordinates storage**
  - **Validates: Requirements 4.2**

- [x] 11. Map screen
- [x] 11.1 Create MapScreen
  - Display Google Maps (or flutter_map)
  - Show observation markers
  - Implement marker clustering
  - Add bottom sheet for observation details on marker tap
  - Add filter controls
  - Add "Center on current location" button
  - _Requirements: 8.1, 8.2, 8.4, 8.5_

- [x] 11.2 Write widget tests for map
  - Test marker rendering
  - Test clustering activation
  - Test bottom sheet display
  - _Requirements: 8.1, 8.4_

- [x] 12. Trip screens
- [x] 12.1 Create TripsScreen
  - Display trip list
  - Show trip cards with observation count
  - Add create trip FAB
  - Implement pull-to-refresh
  - _Requirements: 9.1, 9.2_

- [x] 12.2 Write property test for trip ordering
  - **Property 13: Trips chronological order**
  - **Validates: Requirements 9.1**

- [x] 12.3 Create TripDetailScreen
  - Display trip information
  - Show map with trip observations
  - List all trip observations
  - Add "Add observation" button
  - Allow removing observations from trip
  - _Requirements: 9.3, 9.4_

- [x] 12.4 Create TripFormScreen
  - Build form with trip fields (name, date, location, description)
  - Implement form validation
  - Handle create and edit modes
  - _Requirements: 9.2_

- [x] 12.5 Create TripCard widget
  - Display trip name and date
  - Show observation count
  - Show location
  - Make tappable for navigation
  - _Requirements: 9.1_

- [x] 13. Community/shared observations
- [x] 13.1 Create CommunityScreen
  - Display shared observations list
  - Add filter by species/location
  - Add map view toggle
  - Show owner username for each observation
  - Implement pagination
  - _Requirements: 10.1, 10.2, 10.3, 10.5_

- [x] 13.2 Write property test for shared filter
  - **Property 20: Shared observations filter**
  - **Validates: Requirements 10.1**

- [x] 13.3 Add map view for shared observations
  - Display all shared observations with coordinates on map
  - Update map when filters applied
  - Show observation details on marker tap
  - _Requirements: 10.4_

- [x] 14. Profile and settings
- [x] 14.1 Create ProfileScreen
  - Display user information
  - Show statistics (total observations, species count)
  - Add settings button
  - Add logout button
  - _Requirements: 13.4, 13.5_

- [x] 14.2 Create SettingsScreen
  - Add map type preference selector
  - Add auto-sync toggle
  - Add notification preferences
  - Show cache size
  - Add "Clear cache" button
  - Show app version
  - _Requirements: 13.1, 13.2, 13.3, 14.1, 14.2_

- [x] 14.3 Write property test for settings persistence
  - **Property 27: Settings persistence**
  - **Validates: Requirements 13.2, 13.3**

- [x] 14.4 Write property test for cache management
  - **Property 28: Logout preserves pending syncs**
  - **Property 29: Cache size calculation**
  - **Property 30: Cache clearing preserves pending syncs**
  - **Validates: Requirements 13.5, 14.1, 14.2**

- [x] 15. Sync status and notifications
- [x] 15.1 Create SyncStatusBanner widget
  - Show pending sync count
  - Display sync progress
  - Show sync errors
  - Allow manual sync trigger
  - _Requirements: 5.5, 15.1, 15.2_

- [x] 15.2 Implement local notifications
  - Add flutter_local_notifications dependency
  - Configure notification channels
  - Show notification on sync complete
  - Show notification on sync error
  - Handle notification taps
  - _Requirements: 15.1, 15.2, 15.3_

- [x] 15.3 Implement background sync
  - Configure background fetch
  - Implement background sync task
  - Respect auto-sync setting
  - _Requirements: 15.5_

- [x] 16. Photo viewing and management
- [x] 16.1 Create PhotoViewScreen
  - Display photo in full screen
  - Support pinch-to-zoom
  - Show observation details overlay
  - Add share button
  - _Requirements: 12.1, 12.2, 12.3_

- [x] 16.2 Implement photo caching
  - Use cached_network_image for automatic caching
  - Implement LRU cache eviction
  - Handle cache size limits
  - Show placeholder for failed loads
  - _Requirements: 12.4, 12.5_

- [x] 17. Search and filtering
- [x] 17.1 Implement search debouncing
  - Add debounce logic to search input
  - Prevent excessive API calls
  - Show loading indicator during search
  - _Requirements: 11.5_

- [x] 17.2 Write property test for debouncing
  - **Property 24: Search debouncing**
  - **Validates: Requirements 11.5**

- [x] 17.2 Implement filter UI
  - Create filter bottom sheet
  - Add species filter
  - Add location filter
  - Add date range picker
  - Add "Clear all" button
  - _Requirements: 11.1, 11.2, 11.3_

- [x] 18. Error handling and recovery
- [x] 18.1 Create error handling utilities
  - Implement error message mapping
  - Create error display widgets
  - Add retry mechanisms
  - _Requirements: 17.1, 17.2, 17.3, 17.4_

- [x] 18.2 Write property test for error handling
  - **Property 32: Photo upload retry**
  - **Property 33: Offline mode activation**
  - **Validates: Requirements 17.3, 17.4**

- [x] 18.3 Implement offline mode indicator
  - Show banner when offline
  - Update UI to indicate offline status
  - Disable online-only features
  - _Requirements: 5.1, 17.4_

- [x] 19. Validation and security
- [x] 19.1 Implement form validation
  - Create validation utilities
  - Add field-specific validators
  - Implement real-time validation
  - _Requirements: 18.1, 18.2, 18.3, 18.4_

- [x] 19.2 Implement secure storage
  - Use FlutterSecureStorage for tokens
  - Encrypt sensitive local data
  - Clear sensitive data on logout
  - _Requirements: 20.1, 20.3, 20.5_

- [x] 19.3 Write property test for security
  - **Property 36: Secure token storage**
  - **Property 37: HTTPS enforcement**
  - **Property 38: Sensitive data encryption**
  - **Validates: Requirements 20.1, 20.2, 20.3**

- [x] 20. Accessibility
- [x] 20.1 Add accessibility labels
  - Add semantic labels to all interactive elements
  - Provide image descriptions
  - Ensure proper focus order
  - _Requirements: 19.1, 19.5_

- [x] 20.2 Implement accessibility features
  - Support dynamic font sizing
  - Add high contrast mode support
  - Test with screen readers (TalkBack, VoiceOver)
  - _Requirements: 19.2, 19.3_

- [x] 21. Performance optimization
- [x] 21.1 Optimize image loading
  - Implement lazy loading for images
  - Use thumbnails in lists
  - Compress images before upload
  - _Requirements: 16.3_

- [x] 21.2 Optimize database queries
  - Add indexes to frequently queried columns
  - Use transactions for batch operations
  - Implement query result caching
  - _Requirements: 16.2_

- [x] 21.3 Optimize app size
  - Remove unused dependencies
  - Optimize image assets
  - Enable code shrinking
  - _Requirements: 16.1_

- [x] 22. Testing
- [x] 22.1 Write unit tests for repositories
  - Test all repository methods with mocked dependencies
  - Test offline scenarios
  - Test error handling
  - _Requirements: All repository requirements_

- [x] 22.2 Write unit tests for services
  - Test API service with mocked HTTP client
  - Test sync service logic
  - Test GPS service
  - _Requirements: All service requirements_

- [x] 22.3 Write widget tests
  - Test all major screens render correctly
  - Test user interactions
  - Test navigation
  - _Requirements: All UI requirements_

- [x] 22.4 Write integration tests
  - Test complete user flows
  - Test offline mode
  - Test sync process
  - _Requirements: All integration scenarios_

- [x] 23. Platform-specific configuration
- [x] 23.1 Configure iOS
  - Set up Info.plist with permissions
  - Configure app icons and launch screen
  - Set up signing and provisioning
  - Test on iOS simulator and device
  - _Requirements: All_

- [x] 23.2 Configure Android
  - Set up AndroidManifest.xml with permissions
  - Configure app icons and splash screen
  - Set up signing configuration
  - Test on Android emulator and device
  - _Requirements: All_

- [x] 24. Documentation
- [x] 24.1 Write README
  - Document setup instructions
  - List dependencies and versions
  - Explain project structure
  - Add screenshots
  - _Requirements: All_

- [x] 24.2 Add code documentation
  - Document all public APIs
  - Add inline comments for complex logic
  - Create architecture documentation
  - _Requirements: All_

- [x] 25. Final checkpoint - Integration testing
  - Test complete app flow on iOS
  - Test complete app flow on Android
  - Test offline mode thoroughly
  - Test sync in various network conditions
  - Test camera and GPS on real devices
  - Ensure all tests pass, ask the user if questions arise.
