# Architecture Documentation

## Overview

The Bird Watching Mobile App follows **Clean Architecture** principles with clear separation of concerns across three main layers: Presentation, Domain, and Data. This architecture ensures maintainability, testability, and scalability.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌────────────────────────────────────────────────┐    │
│  │              UI Screens & Widgets              │    │
│  │  - LoginScreen, ObservationsScreen, etc.      │    │
│  │  - Reusable widgets (Cards, Forms, etc.)      │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│  ┌──────────────────▼─────────────────────────────┐    │
│  │         BLoC State Management                  │    │
│  │  - AuthBloc, ObservationBloc, TripBloc        │    │
│  │  - Events, States, Business Logic             │    │
│  └──────────────────┬─────────────────────────────┘    │
└───────────────────┬─┴──────────────────────────────────┘
                    │
┌───────────────────▼────────────────────────────────────┐
│                    Domain Layer                         │
│  ┌────────────────────────────────────────────────┐    │
│  │              Business Entities                 │    │
│  │  - User, Observation, Trip                     │    │
│  └────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────┐    │
│  │              Use Cases (Optional)              │    │
│  │  - Business logic operations                   │    │
│  └────────────────────────────────────────────────┘    │
└───────────────────┬────────────────────────────────────┘
                    │
┌───────────────────▼────────────────────────────────────┐
│                     Data Layer                          │
│  ┌────────────────────────────────────────────────┐    │
│  │              Repositories                      │    │
│  │  - AuthRepository, ObservationRepository       │    │
│  │  - Coordinate data sources                     │    │
│  └──────────┬───────────────────┬──────────────────┘    │
│             │                   │                        │
│  ┌──────────▼────────┐  ┌──────▼──────────────┐        │
│  │   Remote Data     │  │   Local Data        │        │
│  │   - API Service   │  │   - SQLite DB       │        │
│  │   - HTTP Client   │  │   - Secure Storage  │        │
│  └──────────┬────────┘  └──────┬──────────────┘        │
└─────────────┼──────────────────┼─────────────────────┘
              │                  │
              │                  │ (Offline Queue)
              │                  │
┌─────────────▼──────────────────▼─────────────────────┐
│              External Systems                         │
│  - Backend API (Rust/Actix-web)                      │
│  - Device Hardware (Camera, GPS)                     │
│  - Platform Services (Keychain, Keystore)            │
└───────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer

**Location**: `lib/presentation/`

**Responsibilities:**
- Display UI to users
- Handle user interactions
- Manage UI state
- Navigate between screens
- Display loading, error, and success states

**Components:**

#### Screens (`presentation/screens/`)
Individual app screens organized by feature:
- `auth/` - Login and registration screens
- `observations/` - Observation list, detail, and form screens
- `trips/` - Trip management screens
- `map/` - Map visualization screen
- `community/` - Shared observations screen
- `profile/` - User profile and settings screens

#### Widgets (`presentation/widgets/`)
Reusable UI components:
- `observation_card.dart` - Display observation in list
- `trip_card.dart` - Display trip in list
- `photo_picker.dart` - Camera and gallery picker
- `location_picker.dart` - GPS location selector
- `sync_status_banner.dart` - Offline sync status indicator
- `error_display.dart` - Error message display
- `filter_bottom_sheet.dart` - Search filters

#### BLoCs (`presentation/blocs/`)
State management using BLoC pattern:
- `auth/` - Authentication state (login, logout, token)
- `observation/` - Observation CRUD and sync state
- `trip/` - Trip management state
- `map/` - Map markers and clustering state
- `sync/` - Offline sync coordination state

**BLoC Pattern:**
```dart
// Event: User action
class LoginRequested extends AuthEvent {
  final String username;
  final String password;
}

// State: UI state
class Authenticated extends AuthState {
  final User user;
  final String token;
}

// BLoC: Business logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(
        event.username,
        event.password,
      );
      emit(Authenticated(user: result.user, token: result.token));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
```

### 2. Domain Layer

**Location**: `lib/domain/`

**Responsibilities:**
- Define business entities
- Define business rules
- Independent of frameworks and external systems

**Components:**

#### Entities (`domain/entities/`)
Pure business objects without framework dependencies:
- Core business models
- Business logic methods
- Validation rules

**Note**: In this app, entities are currently combined with data models in `lib/data/models/` for simplicity. In larger apps, these would be separated.

#### Use Cases (`domain/use_cases/`)
Business logic operations:
- Encapsulate specific business operations
- Coordinate between repositories
- Enforce business rules

**Note**: Currently, business logic is handled in BLoCs. Use cases can be extracted for complex operations.

### 3. Data Layer

**Location**: `lib/data/`

**Responsibilities:**
- Fetch data from external sources
- Store data locally
- Manage data synchronization
- Handle caching strategies

**Components:**

#### Models (`data/models/`)
Data transfer objects with serialization:
```dart
class Observation {
  final String id;
  final String userId;
  final String speciesName;
  final DateTime observationDate;
  final double? latitude;
  final double? longitude;
  final bool pendingSync;
  
  // JSON serialization
  Map<String, dynamic> toJson() { ... }
  factory Observation.fromJson(Map<String, dynamic> json) { ... }
  
  // SQLite serialization
  Map<String, dynamic> toMap() { ... }
  factory Observation.fromMap(Map<String, dynamic> map) { ... }
}
```

#### Repositories (`data/repositories/`)
Coordinate data sources and implement business logic:

**AuthRepository**:
- Login, registration, logout
- Token management
- User session handling

**ObservationRepository**:
- CRUD operations for observations
- Offline queue management
- Sync coordination
- Search and filtering

**TripRepository**:
- Trip CRUD operations
- Trip-observation associations

**PhotoRepository**:
- Photo upload and compression
- Photo caching
- Cache management

**Repository Pattern:**
```dart
class ObservationRepository {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;
  
  Future<Observation> createObservation(Observation observation) async {
    if (await _connectivity.isConnected()) {
      // Online: Create via API
      final response = await _apiService.post('/observations', 
        data: observation.toJson());
      final created = Observation.fromJson(response.data);
      await _localDb.insertObservation(created.toMap());
      return created;
    } else {
      // Offline: Store locally with pending sync
      final withPendingSync = observation.copyWith(pendingSync: true);
      await _localDb.insertObservation(
        withPendingSync.toMap(), 
        pendingSync: true
      );
      return withPendingSync;
    }
  }
}
```

#### Services (`data/services/`)
Low-level data operations:

**ApiService**:
- HTTP client wrapper (Dio)
- Request/response interceptors
- Error handling
- Token management

**LocalDatabase**:
- SQLite operations
- CRUD methods
- Query builders
- Migrations

**SecureStorage**:
- Encrypted credential storage
- Platform-specific secure storage (Keychain/Keystore)

**ConnectivityService**:
- Network connectivity monitoring
- Connectivity change stream

**GpsService**:
- GPS location access
- Permission handling
- Location accuracy

**CameraService**:
- Camera access
- Gallery access
- Permission handling

**SyncService**:
- Offline sync coordination
- Retry logic with exponential backoff
- Sync prioritization

## State Management

### BLoC Pattern

The app uses **flutter_bloc** for state management, following the BLoC (Business Logic Component) pattern.

**Benefits:**
- Predictable state changes
- Easy to test
- Separation of business logic from UI
- Reactive programming with streams

**Flow:**
```
User Action → Event → BLoC → Repository → Data Source
                ↓
            New State → UI Update
```

**Example:**
```dart
// 1. User taps login button
onPressed: () {
  context.read<AuthBloc>().add(
    LoginRequested(username: username, password: password)
  );
}

// 2. BLoC receives event and processes
on<LoginRequested>((event, emit) async {
  emit(AuthLoading());
  final result = await _authRepository.login(event.username, event.password);
  emit(Authenticated(user: result.user, token: result.token));
});

// 3. UI reacts to state changes
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return CircularProgressIndicator();
    if (state is Authenticated) return HomeScreen();
    if (state is AuthError) return ErrorWidget(state.message);
    return LoginForm();
  },
)
```

## Dependency Injection

### GetIt Service Locator

The app uses **get_it** for dependency injection and service location.

**Configuration**: `lib/config/dependency_injection.dart`

**Registration:**
```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Services (Singletons)
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<ApiService>(),
      secureStorage: getIt<SecureStorage>(),
    ),
  );
  
  // BLoCs (Factories - new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
}
```

**Usage:**
```dart
// In widgets
final authBloc = getIt<AuthBloc>();

// With BlocProvider
BlocProvider(
  create: (_) => getIt<AuthBloc>(),
  child: LoginScreen(),
)
```

## Data Flow Patterns

### Online Mode

```
User Action
    ↓
  BLoC Event
    ↓
  Repository
    ↓
  API Service → Backend API
    ↓
  Response
    ↓
  Local Cache (optional)
    ↓
  BLoC State
    ↓
  UI Update
```

### Offline Mode

```
User Action
    ↓
  BLoC Event
    ↓
  Repository (detects offline)
    ↓
  Local Database (with pendingSync flag)
    ↓
  BLoC State (with pending indicator)
    ↓
  UI Update (shows offline indicator)
    ↓
  [When online]
    ↓
  Sync Service
    ↓
  API Service → Backend API
    ↓
  Mark as synced
    ↓
  UI Update (removes offline indicator)
```

### Sync Process

```
Connectivity Restored
    ↓
  Sync Service
    ↓
  Get Pending Observations
    ↓
  For each observation:
    ├─ Upload photo (if exists)
    ├─ Create/Update via API
    ├─ Mark as synced
    └─ Handle errors (retry with backoff)
    ↓
  Emit Sync Complete
    ↓
  UI Update
```

## Error Handling

### Error Hierarchy

```dart
// Base error class
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

// Specific error types
class NetworkError extends AppError { ... }
class AuthenticationError extends AppError { ... }
class ValidationError extends AppError { ... }
class StorageError extends AppError { ... }
```

### Error Handling Strategy

1. **Repository Level**: Catch and transform errors
2. **BLoC Level**: Emit error states
3. **UI Level**: Display user-friendly messages

**Example:**
```dart
// Repository
try {
  final response = await _apiService.post('/observations', data: data);
  return Observation.fromJson(response.data);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    throw AuthenticationError('Session expired');
  } else if (e.type == DioExceptionType.connectionTimeout) {
    throw NetworkError('Connection timeout');
  }
  throw NetworkError('Failed to create observation');
}

// BLoC
on<CreateObservation>((event, emit) async {
  try {
    final observation = await _repository.createObservation(event.observation);
    emit(ObservationCreated(observation));
  } on AuthenticationError catch (e) {
    emit(ObservationError(message: e.message, requiresAuth: true));
  } on NetworkError catch (e) {
    emit(ObservationError(message: e.message, canRetry: true));
  }
});

// UI
BlocListener<ObservationBloc, ObservationState>(
  listener: (context, state) {
    if (state is ObservationError) {
      if (state.requiresAuth) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    }
  },
)
```

## Testing Strategy

### Test Pyramid

```
        /\
       /  \
      / E2E \
     /--------\
    /          \
   / Integration \
  /--------------\
 /                \
/   Unit Tests     \
--------------------
```

### Test Types

**Unit Tests** (`test/repositories/`, `test/services/`):
- Test individual functions and classes
- Mock dependencies
- Fast execution
- High coverage

**Widget Tests** (`test/screens/`, `test/widgets/`):
- Test UI components
- Verify rendering and interactions
- Mock BLoCs and repositories

**Integration Tests** (`test/integration/`):
- Test complete flows
- Verify component integration
- Test with real dependencies (where possible)

**Property-Based Tests** (`test/*_property_test.dart`):
- Test correctness properties
- Generate random test data
- Verify invariants hold across many inputs

### Testing Best Practices

1. **Arrange-Act-Assert**: Structure tests clearly
2. **Mock External Dependencies**: Use mockito for mocking
3. **Test Behavior, Not Implementation**: Focus on outcomes
4. **Keep Tests Fast**: Use mocks to avoid slow operations
5. **Test Edge Cases**: Include error scenarios

## Performance Considerations

### Image Optimization

- **Compression**: Reduce image size before upload (target: 50-80% reduction)
- **Lazy Loading**: Load images only when visible
- **Caching**: Cache images with LRU eviction
- **Thumbnails**: Use smaller images in lists

### Database Optimization

- **Indexing**: Index frequently queried columns (user_id, observation_date)
- **Transactions**: Use transactions for batch operations
- **Pagination**: Load data in chunks (20 items at a time)
- **Query Optimization**: Use efficient queries with proper WHERE clauses

### Memory Management

- **Dispose Resources**: Properly dispose controllers, streams, and subscriptions
- **Limit Cache Size**: Implement cache size limits with automatic eviction
- **Avoid Memory Leaks**: Use weak references where appropriate

### Network Optimization

- **Request Batching**: Batch multiple requests when possible
- **Compression**: Enable gzip compression
- **Caching**: Cache API responses
- **Retry Logic**: Implement exponential backoff for retries

## Security Considerations

### Data Protection

- **Secure Storage**: Use platform secure storage for tokens (Keychain/Keystore)
- **Encryption**: Encrypt sensitive local data
- **HTTPS Only**: All API communication over HTTPS
- **Certificate Pinning**: Consider implementing for production

### Authentication

- **Token Management**: Securely store and refresh tokens
- **Session Timeout**: Implement automatic logout on token expiration
- **Biometric Auth**: Consider adding fingerprint/Face ID (future)

### Input Validation

- **Client-Side Validation**: Validate all user inputs
- **Server-Side Validation**: Never trust client data
- **SQL Injection Prevention**: Use parameterized queries
- **XSS Prevention**: Sanitize user-generated content

## Future Enhancements

### Planned Improvements

1. **Use Cases Layer**: Extract complex business logic from BLoCs
2. **Repository Interfaces**: Add abstract interfaces for better testability
3. **Event Bus**: Implement for cross-feature communication
4. **Modularization**: Split into feature modules
5. **Code Generation**: Use freezed for immutable models
6. **Analytics**: Add analytics tracking
7. **Crash Reporting**: Integrate crash reporting service

### Scalability Considerations

- **Feature Modules**: Organize code by feature for better scalability
- **Lazy Loading**: Load features on demand
- **Code Splitting**: Split code into smaller bundles
- **Microservices**: Consider backend microservices for scale

## References

- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Dependency Injection in Flutter](https://pub.dev/packages/get_it)
- [Flutter Testing](https://docs.flutter.dev/testing)
