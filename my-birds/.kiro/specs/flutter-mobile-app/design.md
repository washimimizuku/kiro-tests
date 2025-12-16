# Design Document

## Overview

The Bird Watching Mobile App is a cross-platform Flutter application for iOS and Android that connects to the existing Rust backend API. The app provides native mobile features including camera integration, GPS tracking, offline support with automatic synchronization, and optimized performance for field use.

The architecture follows Flutter best practices with a clean separation of concerns: presentation layer (UI widgets), business logic layer (BLoC/Cubit for state management), data layer (repositories), and local storage (SQLite + secure storage). The app communicates with the backend via REST API and handles offline scenarios by queuing operations locally and syncing when connectivity is restored.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│              Flutter Mobile App                      │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │         Presentation Layer                  │    │
│  │  - Screens (Login, Observations, Map, etc) │    │
│  │  - Widgets (Cards, Forms, etc)             │    │
│  └──────────────────┬─────────────────────────┘    │
│                     │                                │
│  ┌──────────────────▼─────────────────────────┐    │
│  │      Business Logic Layer (BLoC/Cubit)     │    │
│  │  - AuthBloc, ObservationBloc, TripBloc     │    │
│  │  - State management                         │    │
│  └──────────────────┬─────────────────────────┘    │
│                     │                                │
│  ┌──────────────────▼─────────────────────────┐    │
│  │          Data Layer (Repositories)          │    │
│  │  - AuthRepository, ObservationRepository    │    │
│  │  - API client + Local database              │    │
│  └──────────┬───────────────────┬──────────────┘    │
│             │                   │                    │
│  ┌──────────▼────────┐  ┌──────▼──────────────┐    │
│  │   API Service     │  │  Local Storage      │    │
│  │   (HTTP/REST)     │  │  (SQLite + Secure)  │    │
│  └──────────┬────────┘  └──────┬──────────────┘    │
└─────────────┼──────────────────┼───────────────────┘
              │                  │
              │                  │ (Offline Queue)
              │                  │
┌─────────────▼──────────────────▼───────────────────┐
│           Rust Backend API (Existing)               │
└─────────────────────────────────────────────────────┘
```

### State Management

Using **flutter_bloc** for predictable state management:
- **AuthBloc**: Handles authentication, token management, logout
- **ObservationBloc**: Manages observation CRUD, offline queue, sync
- **TripBloc**: Manages trip CRUD and observation associations
- **MapBloc**: Handles map state, markers, clustering
- **SyncBloc**: Coordinates offline sync operations

### Data Flow

**Online Mode:**
```
User Action → BLoC → Repository → API Service → Backend
                                       ↓
                                  Local Cache (optional)
```

**Offline Mode:**
```
User Action → BLooc → Repository → Local Database (pending sync)
                                       ↓
                              (When online) → Sync Service → Backend
```

## Components and Interfaces

### 1. Presentation Layer

#### Screens

**AuthScreen**
- Login form with username/password
- Registration form
- Password visibility toggle
- "Remember me" checkbox
- Error display

**HomeScreen**
- Bottom navigation bar (Observations, Map, Trips, Community, Profile)
- FAB for quick observation creation
- Sync status indicator

**ObservationsScreen**
- List of observations with thumbnails
- Pull-to-refresh
- Search bar
- Filter options
- Offline indicator for pending syncs

**ObservationDetailScreen**
- Full observation details
- Photo viewer
- Map showing location
- Edit/Delete buttons (if owner)
- Share button

**ObservationFormScreen**
- Species name input
- Date picker (default: today)
- Location text input
- GPS coordinates (auto-captured)
- Photo picker/camera
- Notes text area
- Trip selector
- Share toggle
- Submit button

**MapScreen**
- Interactive map with observation markers
- Marker clustering
- Bottom sheet for observation details
- Filter controls
- Center on current location button

**TripsScreen**
- List of trips
- Trip cards with observation count
- Create trip FAB

**TripDetailScreen**
- Trip information
- Map with trip observations
- List of observations
- Add observation button

**CommunityScreen**
- Shared observations list
- Filter by species/location
- Map view toggle

**ProfileScreen**
- User information
- Settings
- Logout button

**SettingsScreen**
- Map type preference
- Auto-sync toggle
- Cache management
- Notification preferences
- About/Version info

#### Reusable Widgets

**ObservationCard**
- Thumbnail image
- Species name
- Date and location
- Sync status indicator

**TripCard**
- Trip name and date
- Observation count
- Location

**PhotoPicker**
- Camera button
- Gallery button
- Photo preview
- Compression indicator

**LocationPicker**
- Map for coordinate selection
- "Use Current Location" button
- Coordinate display
- Accuracy indicator

**SyncStatusBanner**
- Shows pending sync count
- Sync progress
- Error messages

### 2. Business Logic Layer (BLoC)

#### AuthBloc

**States:**
```dart
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  final String token;
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
}
```

**Events:**
```dart
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String username;
  final String password;
}
class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
}
class LogoutRequested extends AuthEvent {}
class TokenExpired extends AuthEvent {}
```

#### ObservationBloc

**States:**
```dart
abstract class ObservationState {}
class ObservationsLoading extends ObservationState {}
class ObservationsLoaded extends ObservationState {
  final List<Observation> observations;
  final int pendingSyncCount;
}
class ObservationError extends ObservationState {
  final String message;
}
```

**Events:**
```dart
abstract class ObservationEvent {}
class LoadObservations extends ObservationEvent {}
class CreateObservation extends ObservationEvent {
  final Observation observation;
}
class UpdateObservation extends ObservationEvent {
  final Observation observation;
}
class DeleteObservation extends ObservationEvent {
  final String id;
}
class SyncPendingObservations extends ObservationEvent {}
```

#### SyncBloc

**States:**
```dart
abstract class SyncState {}
class SyncIdle extends SyncState {}
class Syncing extends SyncState {
  final int current;
  final int total;
}
class SyncComplete extends SyncState {
  final int synced;
}
class SyncError extends SyncState {
  final String message;
  final int failed;
}
```

### 3. Data Layer

#### Repositories

**AuthRepository**
```dart
class AuthRepository {
  final ApiService _apiService;
  final SecureStorage _secureStorage;
  
  Future<LoginResponse> login(String username, String password);
  Future<User> register(String username, String email, String password);
  Future<void> logout();
  Future<String?> getStoredToken();
  Future<void> storeToken(String token);
  Future<void> clearToken();
  Future<User?> getCurrentUser();
}
```

**ObservationRepository**
```dart
class ObservationRepository {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;
  
  Future<List<Observation>> getObservations({bool forceRefresh = false});
  Future<Observation> getObservationById(String id);
  Future<Observation> createObservation(Observation observation);
  Future<Observation> updateObservation(Observation observation);
  Future<void> deleteObservation(String id);
  Future<List<Observation>> getPendingSyncObservations();
  Future<void> syncObservation(Observation observation);
  Future<List<Observation>> searchObservations(String query);
}
```

**TripRepository**
```dart
class TripRepository {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  
  Future<List<Trip>> getTrips();
  Future<Trip> getTripById(String id);
  Future<Trip> createTrip(Trip trip);
  Future<Trip> updateTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<List<Observation>> getTripObservations(String tripId);
}
```

**PhotoRepository**
```dart
class PhotoRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  final ImageCompressor _compressor;
  
  Future<String> uploadPhoto(File photo);
  Future<File> compressPhoto(File photo, {int quality = 85});
  Future<File?> getCachedPhoto(String url);
  Future<void> cachePhoto(String url, File photo);
  Future<void> clearPhotoCache();
  Future<int> getCacheSize();
}
```

#### Services

**ApiService**
```dart
class ApiService {
  final Dio _dio;
  final String baseUrl;
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParams});
  Future<Response> post(String path, {dynamic data});
  Future<Response> put(String path, {dynamic data});
  Future<Response> delete(String path);
  Future<Response> uploadFile(String path, File file);
  
  void setAuthToken(String token);
  void clearAuthToken();
}
```

**LocalDatabase (SQLite)**
```dart
class LocalDatabase {
  final Database _db;
  
  // Observations
  Future<void> insertObservation(Observation observation, {bool pendingSync = false});
  Future<List<Observation>> getObservations();
  Future<Observation?> getObservationById(String id);
  Future<void> updateObservation(Observation observation);
  Future<void> deleteObservation(String id);
  Future<List<Observation>> getPendingSyncObservations();
  Future<void> markAsSynced(String id);
  
  // Trips
  Future<void> insertTrip(Trip trip);
  Future<List<Trip>> getTrips();
  Future<Trip?> getTripById(String id);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String id);
  
  // Cache management
  Future<void> clearCache();
  Future<int> getDatabaseSize();
}
```

**SecureStorage**
```dart
class SecureStorage {
  final FlutterSecureStorage _storage;
  
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}
```

**ConnectivityService**
```dart
class ConnectivityService {
  Stream<ConnectivityResult> get connectivityStream;
  Future<bool> isConnected();
  Future<bool> hasInternetAccess();
}
```

**GpsService**
```dart
class GpsService {
  Future<Position?> getCurrentPosition();
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Stream<Position> getPositionStream();
}
```

**CameraService**
```dart
class CameraService {
  Future<File?> takePicture();
  Future<File?> pickFromGallery();
  Future<bool> isCameraAvailable();
}
```

**SyncService**
```dart
class SyncService {
  final ObservationRepository _observationRepo;
  final ConnectivityService _connectivity;
  
  Future<SyncResult> syncPendingObservations();
  Future<void> syncObservation(Observation observation);
  Stream<SyncProgress> get syncProgressStream;
  void startAutoSync();
  void stopAutoSync();
}
```

### 4. Data Models

**User**
```dart
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
}
```

**Observation**
```dart
class Observation {
  final String id;
  final String userId;
  final String? tripId;
  final String speciesName;
  final DateTime observationDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? photoUrl;
  final String? localPhotoPath;  // For offline photos
  final bool isShared;
  final bool pendingSync;  // Local only
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Trip**
```dart
class Trip {
  final String id;
  final String userId;
  final String name;
  final DateTime tripDate;
  final String location;
  final String? description;
  final int observationCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**SyncResult**
```dart
class SyncResult {
  final int totalAttempted;
  final int successful;
  final int failed;
  final List<String> failedIds;
  final List<String> errors;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Authentication Properties

**Property 1: Valid login stores token**
*For any* valid username and password combination, successful authentication should result in a token being securely stored and retrievable.
**Validates: Requirements 1.2**

**Property 2: Logout clears credentials**
*For any* authenticated user, logging out should remove all stored authentication tokens and credentials from secure storage.
**Validates: Requirements 1.5, 13.5, 20.5**

**Property 3: Registration creates account**
*For any* valid registration data (unique username, valid email, password), registration should create a new user account and automatically authenticate the user.
**Validates: Requirements 2.2, 2.3**

**Property 4: Duplicate registration rejection**
*For any* registration attempt with an existing username or email, the system should reject the registration with an appropriate error.
**Validates: Requirements 2.4**

### Photo Management Properties

**Property 5: Photo compression reduces size**
*For any* photo file, compression should reduce the file size while maintaining acceptable quality (target: 50-80% size reduction).
**Validates: Requirements 3.3**

**Property 6: Observation with photo uploads successfully**
*For any* observation created with a photo, the photo should be uploaded to the backend and the observation should contain a valid photo URL.
**Validates: Requirements 3.4**

### GPS and Location Properties

**Property 7: GPS coordinates storage**
*For any* observation created with GPS coordinates, the latitude and longitude should be stored and retrievable.
**Validates: Requirements 4.2**

**Property 8: Coordinate validation**
*For any* coordinate input, latitude outside [-90, 90] or longitude outside [-180, 180] should be rejected with a validation error.
**Validates: Requirements 18.2**

### Offline Mode Properties

**Property 9: Offline observation creation**
*For any* observation created without network connectivity, the observation should be stored locally with a pending sync status.
**Validates: Requirements 5.1, 5.2**

**Property 10: Automatic sync on connectivity**
*For any* pending sync observations, when network connectivity is restored, all pending observations should be automatically synced to the backend.
**Validates: Requirements 5.3**

**Property 11: Sync retry with exponential backoff**
*For any* failed sync attempt, the system should retry with exponentially increasing delays (e.g., 1s, 2s, 4s, 8s).
**Validates: Requirements 5.4**

### Data Ordering Properties

**Property 12: Observations chronological order**
*For any* list of observations, they should be ordered by observation_date in descending order (most recent first).
**Validates: Requirements 6.1**

**Property 13: Trips chronological order**
*For any* list of trips, they should be ordered by trip_date in descending order (most recent first).
**Validates: Requirements 9.1**

### CRUD Operation Properties

**Property 14: Observation creation persistence**
*For any* valid observation data, creating an observation should result in the observation being stored and retrievable.
**Validates: Requirements 7.2**

**Property 15: Observation update persistence**
*For any* observation owned by the user, updating any field should result in the new values being persisted and retrievable.
**Validates: Requirements 7.3**

**Property 16: Unauthorized edit rejection**
*For any* observation not owned by the current user, attempting to edit should be rejected with an authorization error.
**Validates: Requirements 7.4**

**Property 17: Trip creation persistence**
*For any* valid trip data, creating a trip should result in the trip being stored and retrievable.
**Validates: Requirements 9.2**

**Property 18: Trip-observation association**
*For any* trip and observation owned by the same user, associating the observation with the trip should result in the observation appearing in the trip's observation list.
**Validates: Requirements 9.3, 9.4**

**Property 19: Trip deletion preserves observations**
*For any* trip with associated observations, deleting the trip should remove the trip but preserve all observations.
**Validates: Requirements 9.5**

### Filtering and Search Properties

**Property 20: Shared observations filter**
*For any* query for shared observations, the results should contain all and only observations where is_shared is true.
**Validates: Requirements 10.1**

**Property 21: Search filter correctness**
*For any* search query, results should contain all and only observations where species_name or location contains the query string (case-insensitive).
**Validates: Requirements 10.3, 11.1**

**Property 22: Date range filter correctness**
*For any* date range filter, results should contain all and only observations where observation_date is within the specified range.
**Validates: Requirements 11.2**

**Property 23: Filter clearing returns all results**
*For any* active filters, clearing all filters should return the complete unfiltered observation list.
**Validates: Requirements 11.3**

**Property 24: Search debouncing**
*For any* rapid sequence of search inputs within a short time window (e.g., 300ms), only the final input should trigger an API call.
**Validates: Requirements 11.5**

### Pagination Properties

**Property 25: Pagination page size**
*For any* paginated list request, the number of items returned should not exceed the specified page size (default: 20).
**Validates: Requirements 10.5**

### Cache Management Properties

**Property 26: Cached photo offline access**
*For any* cached photo, the photo should be accessible and displayable when the device is offline.
**Validates: Requirements 12.5**

**Property 27: Settings persistence**
*For any* user preference change (map type, auto-sync, etc.), the setting should be persisted locally and applied on app restart.
**Validates: Requirements 13.2, 13.3**

**Property 28: Logout preserves pending syncs**
*For any* logout action, all cached data should be cleared except observations with pending sync status.
**Validates: Requirements 13.5**

**Property 29: Cache size calculation**
*For any* cached data, the calculated cache size should accurately reflect the total storage used by photos and observation data.
**Validates: Requirements 14.1**

**Property 30: Cache clearing preserves pending syncs**
*For any* cache clear operation, all cached photos and observation data should be removed except observations with pending sync status.
**Validates: Requirements 14.2**

**Property 31: Sync prioritizes photos**
*For any* sync operation with multiple pending observations, observations with photos should be synced before observations without photos.
**Validates: Requirements 14.4**

### Error Handling Properties

**Property 32: Photo upload retry**
*For any* failed photo upload, the system should allow retrying the upload without recreating the observation.
**Validates: Requirements 17.3**

**Property 33: Offline mode activation**
*For any* network error when attempting to reach the backend, the system should automatically enable offline mode.
**Validates: Requirements 17.4**

### Validation Properties

**Property 34: Future date rejection**
*For any* observation with an observation_date in the future, the creation or update should be rejected with a validation error.
**Validates: Requirements 18.3**

**Property 35: Text length validation**
*For any* text field with a maximum length constraint, input exceeding that length should be truncated or rejected with a validation error.
**Validates: Requirements 18.4**

### Security Properties

**Property 36: Secure token storage**
*For any* authentication token, it should be stored using platform secure storage (iOS Keychain / Android Keystore) and not in plain text.
**Validates: Requirements 20.1**

**Property 37: HTTPS enforcement**
*For any* API request, the URL should use HTTPS protocol exclusively.
**Validates: Requirements 20.2**

**Property 38: Sensitive data encryption**
*For any* sensitive data stored locally (tokens, passwords), it should be encrypted before storage.
**Validates: Requirements 20.3**

## Error Handling

### Network Errors
- **No Connection**: Enable offline mode, queue operations
- **Timeout**: Retry with exponential backoff
- **Server Error (5xx)**: Display error, allow retry
- **Client Error (4xx)**: Display specific error message

### Authentication Errors
- **401 Unauthorized**: Clear token, redirect to login
- **403 Forbidden**: Display "Access denied" message
- **Token Expired**: Refresh token or re-authenticate

### Validation Errors
- **Missing Fields**: Highlight fields, show error messages
- **Invalid Format**: Show format requirements
- **Out of Range**: Show valid range

### Device Errors
- **Camera Unavailable**: Fallback to gallery picker
- **GPS Unavailable**: Allow manual coordinate entry
- **Storage Full**: Prompt to clear cache
- **Permission Denied**: Show explanation, link to settings

## Testing Strategy

### Unit Testing

**Dart Unit Tests:**
- Test BLoC state transitions
- Test repository methods with mocked dependencies
- Test data model serialization/deserialization
- Test validation logic
- Test utility functions (date formatting, coordinate validation)
- Test sync logic with mocked connectivity

**Widget Testing:**
- Test individual widgets render correctly
- Test user interactions (button taps, form inputs)
- Test navigation between screens
- Test error state displays

### Integration Testing

**Flutter Integration Tests:**
- Test complete user flows (login → create observation → view on map)
- Test offline mode (create observation offline → sync when online)
- Test camera integration
- Test GPS integration
- Test photo upload flow

### Property-Based Testing

For critical business logic, use property-based testing:

**Dart Package:** `test` with custom property generators

**Property Test Coverage:**
- Generate random observations and verify CRUD operations (Properties 14, 15, 16)
- Generate random coordinates and verify validation (Property 8)
- Generate random sync scenarios and verify retry logic (Property 11)
- Generate random search queries and verify filtering (Properties 21, 22, 23)
- Generate random cache operations and verify preservation of pending syncs (Properties 28, 30)

### End-to-End Testing

**Manual Testing:**
- Test on real iOS and Android devices
- Test in various network conditions (WiFi, cellular, offline)
- Test with different GPS accuracy levels
- Test with low storage scenarios
- Test camera on different devices

## Performance Considerations

### App Size
- Target: < 50MB download size
- Use code splitting and lazy loading
- Optimize image assets
- Remove unused dependencies

### Memory Management
- Implement image caching with LRU eviction
- Limit concurrent photo uploads
- Clear large objects when not in use
- Monitor memory usage in profiler

### Battery Optimization
- Use GPS only when needed (not continuous tracking)
- Batch sync operations
- Implement efficient background sync
- Avoid unnecessary wake locks

### Network Optimization
- Compress photos before upload (target: < 1MB per photo)
- Implement request caching
- Use pagination for large lists
- Batch API requests when possible

### Database Optimization
- Index frequently queried columns (user_id, observation_date)
- Use transactions for batch operations
- Implement database migrations carefully
- Regular vacuum operations

## Security Considerations

### Data Protection
- Use FlutterSecureStorage for tokens
- Encrypt local database (SQLCipher)
- Clear sensitive data on logout
- Implement certificate pinning for API calls

### Authentication
- Store tokens securely
- Implement token refresh
- Handle token expiration gracefully
- Support biometric authentication (future)

### Privacy
- Request permissions with clear explanations
- Allow users to disable location tracking
- Provide option to delete all data
- Respect user privacy settings

## Technology Stack

### Core Framework
- **Flutter**: 3.16+ (latest stable)
- **Dart**: 3.2+

### State Management
- **flutter_bloc**: ^8.1.3 - BLoC pattern implementation
- **equatable**: ^2.0.5 - Value equality for states

### Networking
- **dio**: ^5.4.0 - HTTP client
- **connectivity_plus**: ^5.0.2 - Network connectivity
- **pretty_dio_logger**: ^1.3.1 - API logging (debug only)

### Local Storage
- **sqflite**: ^2.3.0 - SQLite database
- **flutter_secure_storage**: ^9.0.0 - Secure credential storage
- **path_provider**: ^2.1.1 - File system paths
- **shared_preferences**: ^2.2.2 - Simple key-value storage

### Location & Maps
- **geolocator**: ^10.1.0 - GPS location
- **google_maps_flutter**: ^2.5.0 - Google Maps (or flutter_map for OSM)
- **geocoding**: ^2.1.1 - Reverse geocoding (optional)

### Camera & Images
- **image_picker**: ^1.0.5 - Camera and gallery access
- **flutter_image_compress**: ^2.1.0 - Image compression
- **cached_network_image**: ^3.3.0 - Image caching

### UI Components
- **flutter_svg**: ^2.0.9 - SVG support
- **intl**: ^0.18.1 - Internationalization and date formatting
- **flutter_slidable**: ^3.0.0 - Swipe actions
- **pull_to_refresh**: ^2.0.0 - Pull to refresh

### Utilities
- **uuid**: ^4.2.2 - UUID generation
- **rxdart**: ^0.27.7 - Reactive extensions
- **permission_handler**: ^11.1.0 - Permission management

### Testing
- **flutter_test**: SDK - Widget and unit testing
- **mockito**: ^5.4.4 - Mocking
- **integration_test**: SDK - Integration testing
- **flutter_driver**: SDK - E2E testing

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── errors/
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   ├── observation.dart
│   │   └── trip.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── observation_repository.dart
│   │   ├── trip_repository.dart
│   │   └── photo_repository.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── local_database.dart
│   │   ├── secure_storage.dart
│   │   ├── connectivity_service.dart
│   │   ├── gps_service.dart
│   │   ├── camera_service.dart
│   │   └── sync_service.dart
│   └── data_sources/
│       ├── local/
│       └── remote/
├── domain/
│   ├── entities/
│   └── use_cases/
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   ├── observation/
│   │   ├── trip/
│   │   ├── map/
│   │   └── sync/
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── observations/
│   │   ├── trips/
│   │   ├── map/
│   │   ├── community/
│   │   └── profile/
│   └── widgets/
│       ├── observation_card.dart
│       ├── trip_card.dart
│       ├── photo_picker.dart
│       ├── location_picker.dart
│       └── sync_status_banner.dart
└── config/
    ├── routes.dart
    └── dependency_injection.dart
```

## Deployment

### iOS
- Minimum iOS version: 13.0
- Configure Info.plist for permissions (camera, location)
- App Store submission requirements
- TestFlight for beta testing

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Configure AndroidManifest.xml for permissions
- Google Play Store submission
- Internal testing track

### CI/CD
- GitHub Actions or Codemagic for automated builds
- Automated testing on pull requests
- Automated deployment to TestFlight/Play Store beta tracks

## Future Enhancements

- Biometric authentication (fingerprint, Face ID)
- Dark mode support
- Multiple language support (i18n)
- Bird species autocomplete with database
- Bird call recording
- Social features (follow users, like observations)
- Export observations to CSV/GPX
- Apple Watch / Wear OS companion app
- Widget for quick observation entry
- Siri/Google Assistant shortcuts
