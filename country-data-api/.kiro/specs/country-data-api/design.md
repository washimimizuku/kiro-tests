# Design Document

## Overview

The Country Data API is a Python REST API built using Flask that provides access to country information through HTTP endpoints. The system follows a layered architecture with clear separation between the API layer, business logic, data models, and storage. The API will serve country data including names, capitals, populations, regions, and languages, supporting operations like listing all countries, retrieving specific countries, filtering by region, and searching by name.

The implementation emphasizes simplicity and correctness, using in-memory storage for the example dataset and providing comprehensive error handling. The design supports both unit testing and property-based testing to ensure correctness across all operations.

## Architecture

The system follows a three-layer architecture:

1. **API Layer (Flask Routes)**: Handles HTTP requests/responses, parameter parsing, and status codes
2. **Service Layer**: Contains business logic for filtering, searching, and validation
3. **Data Layer**: Manages country data models and in-memory storage

```
┌─────────────────────────────────────┐
│         API Layer (Flask)           │
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

```python
@dataclass
class Country:
    name: str
    capital: str
    population: int
    region: str
    languages: List[str]
    
    def to_dict(self) -> dict:
        """Serialize country to dictionary"""
        
    @classmethod
    def from_dict(cls, data: dict) -> 'Country':
        """Deserialize country from dictionary"""
        
    def validate(self) -> bool:
        """Validate country data integrity"""
```

### Data Store

```python
class CountryDataStore:
    def __init__(self):
        self.countries: List[Country] = []
    
    def load_countries(self, countries: List[Country]) -> None:
        """Load and validate country data"""
    
    def get_all(self) -> List[Country]:
        """Retrieve all countries"""
    
    def get_by_name(self, name: str) -> Optional[Country]:
        """Retrieve country by name (case-insensitive)"""
    
    def filter_by_region(self, region: str) -> List[Country]:
        """Filter countries by region (case-insensitive)"""
    
    def search_by_name(self, query: str) -> List[Country]:
        """Search countries by partial name match (case-insensitive)"""
```

### API Endpoints

```python
GET /api/countries
    Returns: List[Country] (JSON array)
    Status: 200 OK

GET /api/countries/<name>
    Returns: Country (JSON object)
    Status: 200 OK | 404 Not Found

GET /api/countries?region=<region>
    Returns: List[Country] (JSON array)
    Status: 200 OK

GET /api/countries?search=<query>
    Returns: List[Country] (JSON array)
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

We will use **Hypothesis** as the property-based testing library for Python. Hypothesis will generate random test cases to verify that our correctness properties hold across a wide range of inputs.

**Configuration:**
- Each property-based test will run a minimum of 100 iterations
- Tests will use custom strategies to generate valid country data
- Each property-based test will be tagged with a comment referencing the specific correctness property from this design document using the format: `# Feature: country-data-api, Property X: [property text]`

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
- Test deserialization handles missing optional fields

**Integration Tests:**
- Test Flask app initialization with sample data
- Test all endpoints with example data
- Test error handling in request processing

### Test Organization

Tests will be organized in a `tests/` directory:
- `tests/test_models.py`: Country model and validation tests
- `tests/test_data_store.py`: Data store operations tests
- `tests/test_api.py`: API endpoint tests
- `tests/test_properties.py`: Property-based tests using Hypothesis

## Implementation Notes

1. **Flask Framework**: Use Flask for simplicity and ease of demonstration
2. **In-Memory Storage**: Use a simple list-based data store (no database required for this example)
3. **Data Initialization**: Load sample country data on application startup
4. **JSON Serialization**: Use dataclass `asdict()` or custom `to_dict()` methods
5. **Case-Insensitive Matching**: Use `.lower()` for all string comparisons
6. **Error Logging**: Use Python's `logging` module for validation errors

## Sample Data

The API will include sample data for at least 15 countries covering:
- **Europe**: France, Germany, Spain, Italy, United Kingdom
- **Asia**: Japan, China, India, Thailand
- **Americas**: United States, Canada, Brazil, Mexico
- **Africa**: Egypt, South Africa
- **Oceania**: Australia, New Zealand

Each country will have realistic data including multiple languages where applicable.
