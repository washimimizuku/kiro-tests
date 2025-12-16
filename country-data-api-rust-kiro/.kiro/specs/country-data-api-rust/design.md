# Design Document

## Overview

The Country Data API is a Rust REST API built using Axum that provides access to country information through HTTP endpoints. The system follows a layered architecture with clear separation between the API layer, business logic, data models, and storage. The API will serve country data including names, capitals, populations, regions, and languages, supporting operations like listing all countries, retrieving specific countries, filtering by region, and searching by name.

The implementation emphasizes type safety, performance, and correctness, using in-memory storage with async/await for the example dataset and providing comprehensive error handling. The design supports both unit testing and property-based testing to ensure correctness across all operations.

## Architecture

The system follows a three-layer architecture:

1. **API Layer (Axum Routes)**: Handles HTTP requests/responses, parameter parsing, and status codes
2. **Service Layer**: Contains business logic for filtering, searching, and validation
3. **Data Layer**: Manages country data models and in-memory storage

```
┌─────────────────────────────────────┐
│         API Layer (Axum)            │
│  - Route handlers                   │
│  - Request/response formatting      │
│  - HTTP status codes                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Service Layer                │
│  - Country filtering/search logic   │
│  - Data validation                  │
│  - Business rules                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Data Layer                  │
│  - Country model                    │
│  - In-memory data store             │
│  - Data initialization              │
└─────────────────────────────────────┘
```

## Components and Interfaces

### Country Model

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Country {
    pub name: String,
    pub capital: String,
    pub population: i64,
    pub region: String,
    pub languages: Vec<String>,
}

impl Country {
    pub fn validate(&self) -> bool {
        // Validate country data integrity
    }
}
```

### Data Store

```rust
#[derive(Clone)]
pub struct CountryDataStore {
    countries: Arc<RwLock<Vec<Country>>>,
}

impl CountryDataStore {
    pub fn new() -> Self;
    pub async fn load_countries(&self, countries: Vec<Country>);
    pub async fn get_all(&self) -> Vec<Country>;
    pub async fn get_by_name(&self, name: &str) -> Option<Country>;
    pub async fn filter_by_region(&self, region: &str) -> Vec<Country>;
    pub async fn search_by_name(&self, query: &str) -> Vec<Country>;
}
```

### API Endpoints

```rust
GET /api/countries
    Returns: Vec<Country> (JSON array)
    Status: 200 OK

GET /api/countries/<name>
    Returns: Country (JSON object)
    Status: 200 OK | 404 Not Found

GET /api/countries?region=<region>
    Returns: Vec<Country> (JSON array)
    Status: 200 OK

GET /api/countries?search=<query>
    Returns: Vec<Country> (JSON array)
    Status: 200 OK
```

## Data Models

### Country Resource Schema

```json
{
  "name": "string (required, non-empty)",
  "capital": "string (required)",
  "population": "integer (required, >= 0)",
  "region": "string (required)",
  "languages": ["string"] (required, array of strings)
}
```

### Error Response Schema

```json
{
  "error": "string (descriptive error message)"
}
```

### Example Country Data

The API will be initialized with sample data including:
- Countries from multiple regions (Europe, Asia, Americas, Africa, Oceania)
- Varying population sizes
- Multiple languages per country
- At least 10-15 example countries for demonstration

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Complete country retrieval
*For any* set of countries loaded into the data store, calling the get all countries endpoint should return exactly that set of countries with all their data intact.
**Validates: Requirements 1.1, 1.4**

### Property 2: Serialization includes all fields
*For any* valid country resource, serializing it to JSON should produce an object containing name, capital, population, region, and languages fields.
**Validates: Requirements 1.2, 7.3**

### Property 3: Serialization round-trip preserves data
*For any* valid country resource, serializing to JSON and then deserializing should produce an equivalent country object with all fields preserved.
**Validates: Requirements 7.1, 7.2**

### Property 4: Country retrieval by name
*For any* country in the data store, requesting that country by its exact name (regardless of case) should return the same country with all attributes intact.
**Validates: Requirements 2.1, 2.2, 2.4**

### Property 5: Region filtering is case-insensitive and accurate
*For any* set of countries and any region string, filtering by that region (regardless of case) should return only countries whose region matches (case-insensitive), and should return all such countries.
**Validates: Requirements 3.1, 3.2**

### Property 6: Name search is case-insensitive substring matching
*For any* set of countries and any search query string, searching by that query (regardless of case) should return all and only countries whose names contain the query as a substring (case-insensitive).
**Validates: Requirements 4.1, 4.2**

### Property 7: Error responses have consistent structure
*For any* error condition (404, 500, 405), the API response should be valid JSON containing an "error" field with a descriptive message.
**Validates: Requirements 5.4**

### Property 8: Data validation rejects invalid countries
*For any* country with invalid data (empty name, negative population, or non-list languages), attempting to load it into the data store should reject the country and prevent it from being stored.
**Validates: Requirements 6.1, 6.2, 6.3**

## Error Handling

The API implements comprehensive error handling:

1. **404 Not Found**: Returned when a requested country doesn't exist or an invalid endpoint is accessed
2. **405 Method Not Allowed**: Returned when an unsupported HTTP method is used
3. **500 Internal Server Error**: Returned when unexpected errors occur during processing
4. **Validation Errors**: Logged when invalid country data is detected during loading

All error responses follow a consistent JSON format:
```json
{
  "error": "Descriptive error message"
}
```

## Testing Strategy

The Country Data API will employ a dual testing approach combining unit tests and property-based tests to ensure comprehensive correctness validation.

### Property-Based Testing

We will use **proptest** as the property-based testing library for Rust. Proptest will generate random test cases to verify that our correctness properties hold across a wide range of inputs.

**Configuration:**
- Each property-based test will run a minimum of 100 iterations
- Tests will use custom strategies to generate valid country data
- Each property-based test will be tagged with a comment referencing the specific correctness property from this design document using the format: `// Feature: country-data-api-rust, Property X: [property text]`

**Property-Based Tests:**
1. Test complete country retrieval (Property 1)
2. Test serialization field completeness (Property 2)
3. Test serialization round-trip (Property 3)
4. Test country retrieval by name with case variations (Property 4)
5. Test region filtering with case variations (Property 5)
6. Test name search with case variations (Property 6)
7. Test error response structure (Property 7)
8. Test data validation rejection (Property 8)

### Unit Testing

Unit tests will verify specific examples, edge cases, and integration points:

**Core Functionality Tests:**
- Test API returns 200 status for valid requests
- Test empty data store returns empty array
- Test single country retrieval

**Edge Case Tests:**
- Test 404 response for non-existent country
- Test empty array for non-matching region filter
- Test empty array for non-matching search query
- Test empty/whitespace search returns all countries
- Test invalid endpoint returns 404
- Test unsupported HTTP method returns 405

**Integration Tests:**
- Test Axum app initialization with sample data
- Test all endpoints with example data
- Test error handling in request processing

### Test Organization

Tests will be organized in the `tests/` directory:
- `tests/models_test.rs`: Country model and validation tests
- `tests/data_store_test.rs`: Data store operations tests
- `tests/api_test.rs`: API endpoint tests
- `tests/properties_test.rs`: Property-based tests using proptest

## Implementation Notes

1. **Axum Framework**: Use Axum for modern async Rust web development
2. **Tokio Runtime**: Use Tokio for async/await support
3. **In-Memory Storage**: Use Arc<RwLock<Vec<Country>>> for thread-safe in-memory storage
4. **Data Initialization**: Load sample country data on application startup
5. **JSON Serialization**: Use Serde for automatic JSON serialization/deserialization
6. **Case-Insensitive Matching**: Use `.to_lowercase()` for all string comparisons
7. **Error Logging**: Use `tracing` crate for structured logging

## Sample Data

The API will include sample data for at least 15 countries covering:
- **Europe**: France, Germany, Spain, Italy, United Kingdom
- **Asia**: Japan, China, India, Thailand
- **Americas**: United States, Canada, Brazil, Mexico
- **Africa**: Egypt, South Africa
- **Oceania**: Australia, New Zealand

Each country will have realistic data including multiple languages where applicable.
