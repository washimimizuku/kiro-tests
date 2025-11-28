# Design Document

## Overview

The Bird Watching Platform is a full-stack application consisting of a Rust-based REST API backend and a React frontend. The backend uses Actix-web for the HTTP server, SQLx for database operations with PostgreSQL, and JWT for authentication. The frontend uses React with TypeScript, React Router for navigation, and Axios for API communication.

The system follows a layered architecture with clear separation between API routes, business logic, data access, and presentation layers. Data flows from the React frontend through REST endpoints to service layers that coordinate business logic and repository layers that handle database operations.

## Architecture

### Backend Architecture (Rust)

```
┌─────────────────────────────────────────┐
│         React Frontend (Port 3000)       │
└─────────────────┬───────────────────────┘
                  │ HTTP/JSON
┌─────────────────▼───────────────────────┐
│      Actix-web API Server (Port 8080)   │
│  ┌─────────────────────────────────┐    │
│  │   Routes Layer                  │    │
│  │   - Authentication middleware   │    │
│  │   - Request validation          │    │
│  └──────────────┬──────────────────┘    │
│  ┌──────────────▼──────────────────┐    │
│  │   Service Layer                 │    │
│  │   - Business logic              │    │
│  │   - Authorization checks        │    │
│  └──────────────┬──────────────────┘    │
│  ┌──────────────▼──────────────────┐    │
│  │   Repository Layer              │    │
│  │   - Database operations         │    │
│  │   - Query construction          │    │
│  └──────────────┬──────────────────┘    │
└─────────────────┼───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      PostgreSQL Database                │
└─────────────────────────────────────────┘
```

### Frontend Architecture (React)

```
┌─────────────────────────────────────────┐
│           React Application             │
│  ┌─────────────────────────────────┐    │
│  │   Pages/Views                   │    │
│  │   - Login/Register              │    │
│  │   - Dashboard                   │    │
│  │   - Observations                │    │
│  │   - Trips                       │    │
│  └──────────────┬──────────────────┘    │
│  ┌──────────────▼──────────────────┐    │
│  │   Components                    │    │
│  │   - ObservationCard             │    │
│  │   - TripList                    │    │
│  │   - PhotoUpload                 │    │
│  └──────────────┬──────────────────┘    │
│  ┌──────────────▼──────────────────┐    │
│  │   Services/API Client           │    │
│  │   - Axios HTTP client           │    │
│  │   - Token management            │    │
│  └──────────────┬──────────────────┘    │
│  ┌──────────────▼──────────────────┐    │
│  │   State Management              │    │
│  │   - React Context/Hooks         │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Components and Interfaces

### Backend Components

#### 1. Models (Domain Entities)

**User Model**
```rust
struct User {
    id: Uuid,
    username: String,
    email: String,
    password_hash: String,
    created_at: DateTime<Utc>,
}
```

**Observation Model**
```rust
struct Observation {
    id: Uuid,
    user_id: Uuid,
    trip_id: Option<Uuid>,
    species_name: String,
    observation_date: DateTime<Utc>,
    location: String,
    notes: Option<String>,
    photo_url: Option<String>,
    is_shared: bool,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

**Trip Model**
```rust
struct Trip {
    id: Uuid,
    user_id: Uuid,
    name: String,
    trip_date: DateTime<Utc>,
    location: String,
    description: Option<String>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

#### 2. API Routes

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User authentication
- `GET /api/users/me` - Get current user profile
- `POST /api/observations` - Create observation
- `GET /api/observations` - List user's observations
- `GET /api/observations/:id` - Get specific observation
- `PUT /api/observations/:id` - Update observation
- `DELETE /api/observations/:id` - Delete observation
- `GET /api/observations/shared` - List all shared observations
- `POST /api/trips` - Create trip
- `GET /api/trips` - List user's trips
- `GET /api/trips/:id` - Get trip with observations
- `PUT /api/trips/:id` - Update trip
- `DELETE /api/trips/:id` - Delete trip
- `POST /api/photos/upload` - Upload photo
- `GET /api/observations/search` - Search observations

#### 3. Service Layer

**AuthService**
- User registration with password hashing (bcrypt)
- User authentication with JWT token generation
- Token validation

**ObservationService**
- Create, read, update, delete observations
- Authorization checks (user owns observation)
- Sharing logic

**TripService**
- Create, read, update, delete trips
- Associate observations with trips
- Authorization checks

**PhotoService**
- File upload handling
- Storage management (filesystem or cloud storage)
- File type validation

#### 4. Repository Layer

**UserRepository**
- Database operations for users
- Query by username, email, or ID

**ObservationRepository**
- CRUD operations for observations
- Query by user, trip, date range, species, location
- Shared observations query

**TripRepository**
- CRUD operations for trips
- Query trips with associated observations

### Frontend Components

#### 1. Pages

- **LoginPage** - User authentication form
- **RegisterPage** - User registration form
- **DashboardPage** - Overview of recent observations and trips
- **ObservationsPage** - List and manage observations
- **ObservationDetailPage** - View/edit single observation
- **TripsPage** - List and manage trips
- **TripDetailPage** - View trip with observations
- **SharedObservationsPage** - Browse community observations

#### 2. Reusable Components

- **ObservationCard** - Display observation summary
- **ObservationForm** - Create/edit observation
- **TripCard** - Display trip summary
- **TripForm** - Create/edit trip
- **PhotoUpload** - Image upload with preview
- **SearchBar** - Search and filter interface
- **ProtectedRoute** - Authentication guard for routes

#### 3. Services

**ApiService**
- Axios instance with base URL configuration
- Request/response interceptors for token injection
- Error handling

**AuthService**
- Login/register API calls
- Token storage (localStorage)
- Current user state management

## Data Models

### Database Schema

**users table**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**observations table**
```sql
CREATE TABLE observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    species_name VARCHAR(255) NOT NULL,
    observation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    notes TEXT,
    photo_url VARCHAR(500),
    is_shared BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**trips table**
```sql
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    trip_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### API Request/Response Models

**RegisterRequest**
```json
{
    "username": "string",
    "email": "string",
    "password": "string"
}
```

**LoginRequest**
```json
{
    "username": "string",
    "password": "string"
}
```

**LoginResponse**
```json
{
    "token": "string",
    "user": {
        "id": "uuid",
        "username": "string",
        "email": "string"
    }
}
```

**CreateObservationRequest**
```json
{
    "species_name": "string",
    "observation_date": "ISO8601 datetime",
    "location": "string",
    "notes": "string (optional)",
    "photo_url": "string (optional)",
    "trip_id": "uuid (optional)",
    "is_shared": "boolean"
}
```

**ObservationResponse**
```json
{
    "id": "uuid",
    "user_id": "uuid",
    "username": "string",
    "trip_id": "uuid (optional)",
    "species_name": "string",
    "observation_date": "ISO8601 datetime",
    "location": "string",
    "notes": "string (optional)",
    "photo_url": "string (optional)",
    "is_shared": "boolean",
    "created_at": "ISO8601 datetime",
    "updated_at": "ISO8601 datetime"
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### User Management Properties

**Property 1: Valid registration creates unique user**
*For any* valid registration data (username, email, password), creating a user account should result in a new user with a unique identifier that can be retrieved from the database.
**Validates: Requirements 1.1**

**Property 2: Duplicate registration rejection**
*For any* existing user, attempting to register with the same username or email should be rejected with an appropriate error message.
**Validates: Requirements 1.2**

**Property 3: Valid authentication returns token**
*For any* registered user with valid credentials, authentication should return a valid JWT token that can be used for subsequent requests.
**Validates: Requirements 1.3**

**Property 4: Invalid credentials rejection**
*For any* authentication attempt with invalid credentials (wrong password or non-existent user), the system should reject the attempt without revealing which part is invalid.
**Validates: Requirements 1.4**

**Property 5: Profile excludes password**
*For any* authenticated user requesting their profile, the response should contain all user fields except the password hash.
**Validates: Requirements 1.5**

### Observation Management Properties

**Property 6: Observation creation with user association**
*For any* authenticated user and valid observation data, creating an observation should result in a new observation record associated with that user's identifier.
**Validates: Requirements 2.1, 2.2**

**Property 7: User observation isolation**
*For any* user, requesting their observations should return only observations where the user_id matches their identifier, and no observations from other users.
**Validates: Requirements 2.3**

**Property 8: Observation update persistence**
*For any* observation owned by a user, updating any field should result in the new value being persisted and retrievable in subsequent queries.
**Validates: Requirements 2.4**

**Property 9: Unauthorized update rejection**
*For any* observation, attempting to update it as a user who is not the owner should be rejected with an authorization error.
**Validates: Requirements 2.5**

### Photo Management Properties

**Property 10: Photo storage and association**
*For any* observation created with a photo, the photo should be stored and the observation should contain a valid photo_url reference.
**Validates: Requirements 3.1**

**Property 11: Photo reference in response**
*For any* observation with an associated photo, retrieving the observation should include the photo_url in the response.
**Validates: Requirements 3.3**

**Property 12: Cascading photo deletion**
*For any* observation with an associated photo, deleting the observation should also remove the photo from storage.
**Validates: Requirements 3.4**

**Property 13: Photo file type validation**
*For any* file upload, only files with valid image MIME types (image/jpeg, image/png, image/gif, image/webp) should be accepted, and all other file types should be rejected.
**Validates: Requirements 3.5**

### Trip Management Properties

**Property 14: Trip creation**
*For any* authenticated user and valid trip data, creating a trip should result in a new trip record associated with that user.
**Validates: Requirements 4.1**

**Property 15: Observation-trip association**
*For any* observation and trip owned by the same user, associating the observation with the trip should result in the observation's trip_id being set and the observation appearing in the trip's observation list.
**Validates: Requirements 4.2**

**Property 16: Trip details completeness**
*For any* trip, retrieving trip details should return the trip information and all observations where trip_id matches the trip's identifier.
**Validates: Requirements 4.3**

**Property 17: Trip deletion preserves observations**
*For any* trip with associated observations, deleting the trip should remove the trip record but preserve all observations with their trip_id set to null.
**Validates: Requirements 4.4**

**Property 18: Trip update preserves associations**
*For any* trip with associated observations, updating trip fields should modify the trip data while maintaining all observation associations (observations should still reference the trip).
**Validates: Requirements 4.5**

### Sharing Properties

**Property 19: Shared observation visibility**
*For any* observation marked as shared (is_shared = true), all authenticated users should be able to retrieve that observation through the shared observations endpoint.
**Validates: Requirements 5.1**

**Property 20: Private observation restriction**
*For any* observation marked as private (is_shared = false), only the owner should be able to retrieve that observation, and it should not appear in shared observation queries by other users.
**Validates: Requirements 5.2**

**Property 21: Shared observations query correctness**
*For any* query to the shared observations endpoint, the results should contain all and only observations where is_shared = true, regardless of which user created them.
**Validates: Requirements 5.3**

**Property 22: Shared observation includes owner**
*For any* shared observation in query results, the response should include the username of the observation's owner.
**Validates: Requirements 5.4**

**Property 23: Shared observation modification restriction**
*For any* shared observation, attempting to modify it as a user who is not the owner should be rejected with an authorization error.
**Validates: Requirements 5.5**

### Persistence Properties

**Property 24: Immediate persistence**
*For any* create or update operation on any entity, the changes should be immediately visible in subsequent read operations without requiring explicit save or commit actions.
**Validates: Requirements 6.1**

### API Design Properties

**Property 25: HTTP response correctness**
*For any* API request, the response should have an appropriate HTTP status code (2xx for success, 4xx for client errors, 5xx for server errors) and include descriptive error messages for non-success responses.
**Validates: Requirements 7.1, 7.4**

**Property 26: JSON response format**
*For any* API response, the content-type should be application/json and the body should be valid, parseable JSON.
**Validates: Requirements 7.2**

**Property 27: Authentication enforcement**
*For any* protected endpoint, requests without a valid JWT token should be rejected with a 401 status code, and requests with a valid token should be processed.
**Validates: Requirements 7.3**

**Property 28: Invalid JSON rejection**
*For any* API request with a body, if the body is not valid JSON, the request should be rejected with a 400 status code.
**Validates: Requirements 7.5**

### Search and Filtering Properties

**Property 29: Species name search**
*For any* species name query, the search results should contain all and only observations where the species_name field contains the query string (case-insensitive).
**Validates: Requirements 9.1**

**Property 30: Date range filtering**
*For any* date range (start_date, end_date), the filtered results should contain all and only observations where observation_date is between start_date and end_date inclusive.
**Validates: Requirements 9.2**

**Property 31: Location filtering**
*For any* location query, the filtered results should contain all and only observations where the location field matches the query (case-insensitive).
**Validates: Requirements 9.3**

**Property 32: Multiple filter conjunction**
*For any* combination of filters (species, date range, location), the results should contain all and only observations that satisfy all applied filters simultaneously.
**Validates: Requirements 9.4**

### Validation Properties

**Property 33: Missing required fields rejection**
*For any* API request with missing required fields, the request should be rejected with a 400 status code and an error message indicating which specific fields are missing.
**Validates: Requirements 10.1**

**Property 34: Invalid format rejection**
*For any* API request with fields in invalid formats (e.g., malformed email, invalid date string), the request should be rejected with a 400 status code and a validation error message.
**Validates: Requirements 10.2**

**Property 35: Future date rejection**
*For any* observation with an observation_date in the future, the creation or update request should be rejected with a validation error.
**Validates: Requirements 10.3**

**Property 36: Text length validation**
*For any* text field exceeding its maximum length constraint, the request should be rejected with a validation error indicating the field and maximum allowed length.
**Validates: Requirements 10.4**

## Error Handling

### Error Categories

1. **Validation Errors (400)**
   - Missing required fields
   - Invalid data formats
   - Business rule violations (future dates, length constraints)
   - Invalid file types

2. **Authentication Errors (401)**
   - Missing JWT token
   - Invalid or expired token
   - Invalid credentials

3. **Authorization Errors (403)**
   - Attempting to access or modify resources owned by other users

4. **Not Found Errors (404)**
   - Requested resource doesn't exist

5. **Conflict Errors (409)**
   - Duplicate username or email during registration

6. **Server Errors (500)**
   - Database connection failures
   - Unexpected internal errors

### Error Response Format

All errors should return a consistent JSON structure:

```json
{
    "error": {
        "code": "ERROR_CODE",
        "message": "Human-readable error message",
        "details": {
            "field": "Additional context (optional)"
        }
    }
}
```

### Backend Error Handling Strategy

- Use Result<T, E> types throughout Rust code
- Custom error types with From implementations for conversion
- Actix-web error handlers for consistent error responses
- Database transaction rollback on errors
- Logging of all errors with appropriate severity levels

### Frontend Error Handling Strategy

- Axios interceptors for global error handling
- User-friendly error messages displayed in UI
- Automatic token refresh on 401 errors
- Retry logic for network failures
- Form validation before submission to reduce server errors

## Testing Strategy

### Unit Testing

The system will use unit tests to verify specific examples, edge cases, and error conditions:

**Backend (Rust)**
- Test framework: Built-in Rust test framework with `cargo test`
- Mock database operations using test doubles
- Test individual functions in service and repository layers
- Test request/response serialization
- Test password hashing and JWT token generation/validation
- Test edge cases: empty strings, null values, boundary conditions

**Frontend (React)**
- Test framework: Jest and React Testing Library
- Test component rendering with various props
- Test user interactions (clicks, form submissions)
- Test API service functions with mocked Axios
- Test form validation logic
- Test routing and navigation

### Property-Based Testing

The system will use property-based testing to verify universal properties across all inputs:

**Backend (Rust)**
- Property testing library: **proptest** (https://github.com/proptest-rs/proptest)
- Each property-based test MUST run a minimum of 100 iterations
- Each property-based test MUST be tagged with a comment in this format: `// Feature: bird-watching-platform, Property {number}: {property_text}`
- Each correctness property listed above MUST be implemented by a SINGLE property-based test
- Tests should generate random valid inputs (users, observations, trips) and verify properties hold
- Tests should generate random invalid inputs and verify proper rejection
- Focus on testing business logic and data integrity properties

**Property Test Examples:**
- Generate random user registration data and verify unique user creation
- Generate random observations and verify user association
- Generate random search queries and verify result correctness
- Generate random authorization scenarios and verify access control

### Integration Testing

**Backend**
- Test complete API endpoints with real database (test database)
- Test authentication flow end-to-end
- Test file upload and storage
- Test database migrations

**Frontend**
- Test complete user flows (registration → login → create observation)
- Test API integration with mock server
- Test error handling and recovery

### Test Organization

**Backend Structure:**
```
tests/
  unit/
    models/
    services/
    repositories/
  property/
    test_user_properties.rs
    test_observation_properties.rs
    test_trip_properties.rs
    test_sharing_properties.rs
    test_api_properties.rs
  integration/
    test_api_endpoints.rs
```

**Frontend Structure:**
```
src/
  components/
    __tests__/
      ObservationCard.test.tsx
      TripList.test.tsx
  services/
    __tests__/
      api.test.ts
  pages/
    __tests__/
      Dashboard.test.tsx
```

## Security Considerations

### Authentication & Authorization

- Passwords hashed using bcrypt with appropriate cost factor (12+)
- JWT tokens with reasonable expiration (1 hour for access tokens)
- Token validation on all protected endpoints
- User ID extracted from validated token, never from request body
- Authorization checks before any data modification

### Input Validation

- All user inputs validated on both frontend and backend
- SQL injection prevention through parameterized queries (SQLx)
- File upload restrictions (size, type, sanitized filenames)
- Rate limiting on authentication endpoints to prevent brute force

### Data Protection

- HTTPS required for all API communication (production)
- Sensitive data (passwords) never logged
- User data isolation enforced at database query level
- CORS configuration to restrict frontend origins

## Performance Considerations

### Backend Optimization

- Database indexes on frequently queried fields (user_id, species_name, observation_date, is_shared)
- Connection pooling for database connections
- Pagination for list endpoints (observations, trips, shared observations)
- Efficient query construction to avoid N+1 problems
- Async/await throughout for non-blocking I/O

### Frontend Optimization

- Lazy loading of routes
- Image optimization and lazy loading
- Debouncing on search inputs
- Caching of API responses where appropriate
- Pagination or infinite scroll for large lists

### Scalability Considerations

- Stateless API design for horizontal scaling
- Photo storage on external service (S3, CloudFlare R2) rather than filesystem
- Database read replicas for read-heavy operations
- CDN for frontend static assets

## Deployment Architecture

### Development Environment

- Backend: `cargo run` on localhost:8080
- Frontend: `npm start` on localhost:3000
- Database: PostgreSQL in Docker container

### Production Environment

- Backend: Compiled Rust binary in Docker container
- Frontend: Static build served by Nginx or CDN
- Database: Managed PostgreSQL (AWS RDS, DigitalOcean, etc.)
- Photo storage: S3-compatible object storage
- HTTPS via Let's Encrypt or cloud provider SSL

## Technology Stack Summary

### Backend
- **Language:** Rust (latest stable)
- **Web Framework:** Actix-web 4.x
- **Database:** PostgreSQL 14+
- **Database Driver:** SQLx with async support
- **Authentication:** jsonwebtoken crate for JWT
- **Password Hashing:** bcrypt crate
- **Serialization:** serde with serde_json
- **Testing:** proptest for property-based testing
- **Validation:** validator crate

### Frontend
- **Language:** TypeScript
- **Framework:** React 18+
- **Routing:** React Router 6
- **HTTP Client:** Axios
- **State Management:** React Context + Hooks
- **Styling:** CSS Modules or Tailwind CSS
- **Form Handling:** React Hook Form
- **Testing:** Jest + React Testing Library

### Infrastructure
- **Database:** PostgreSQL
- **Photo Storage:** S3-compatible object storage
- **Containerization:** Docker
- **Reverse Proxy:** Nginx (production)
