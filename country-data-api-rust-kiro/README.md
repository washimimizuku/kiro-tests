# Country Data API - Rust

A RESTful API built with Axum that provides access to country information including names, capitals, populations, regions, and languages.

## Features

- Retrieve all countries
- Get specific country by name
- Filter countries by region
- Search countries by name (substring matching)
- Case-insensitive queries
- Async/await with Tokio runtime
- Type-safe with Rust's type system
- Property-based testing with proptest

## Requirements

- Rust 1.70+ (with Cargo)

## Installation

1. Navigate to the project directory:
```bash
cd country-data-api-rust-kiro
```

2. Build the project:
```bash
cargo build --release
```

## Running the Application

Start the server:

```bash
cargo run
```

The API will be available at `http://localhost:5000`

## API Endpoints

### 1. Get All Countries

Retrieve a list of all countries.

**Endpoint:** `GET /api/countries`

**Response:** `200 OK`

```json
[
  {
    "name": "France",
    "capital": "Paris",
    "population": 64756000,
    "region": "Europe",
    "languages": ["French"]
  },
  {
    "name": "Japan",
    "capital": "Tokyo",
    "population": 123295000,
    "region": "Asia",
    "languages": ["Japanese"]
  }
]
```

**Example Request:**
```bash
curl http://localhost:5000/api/countries
```

### 2. Get Country by Name

Retrieve a specific country by its name (case-insensitive).

**Endpoint:** `GET /api/countries/<name>`

**Response:** `200 OK` or `404 Not Found`

**Success Response:**
```json
{
  "name": "France",
  "capital": "Paris",
  "population": 64756000,
  "region": "Europe",
  "languages": ["French"]
}
```

**Error Response (404):**
```json
{
  "error": "Country \"InvalidCountry\" not found"
}
```

**Example Requests:**
```bash
# Get France
curl http://localhost:5000/api/countries/France

# Case-insensitive
curl http://localhost:5000/api/countries/france

# Non-existent country
curl http://localhost:5000/api/countries/Atlantis
```

### 3. Filter Countries by Region

Filter countries by region (case-insensitive).

**Endpoint:** `GET /api/countries?region=<region_name>`

**Query Parameters:**
- `region` (string): The region to filter by (e.g., "Europe", "Asia", "Americas", "Africa", "Oceania")

**Response:** `200 OK`

```json
[
  {
    "name": "France",
    "capital": "Paris",
    "population": 64756000,
    "region": "Europe",
    "languages": ["French"]
  },
  {
    "name": "Germany",
    "capital": "Berlin",
    "population": 83294000,
    "region": "Europe",
    "languages": ["German"]
  }
]
```

**Example Requests:**
```bash
# Get all European countries
curl http://localhost:5000/api/countries?region=Europe

# Case-insensitive
curl http://localhost:5000/api/countries?region=asia

# Non-existent region returns empty array
curl http://localhost:5000/api/countries?region=Antarctica
```

### 4. Search Countries by Name

Search for countries by partial name match (case-insensitive substring matching).

**Endpoint:** `GET /api/countries?search=<query>`

**Query Parameters:**
- `search` (string): The search query (matches any part of the country name)

**Response:** `200 OK`

```json
[
  {
    "name": "United States",
    "capital": "Washington, D.C.",
    "population": 339996000,
    "region": "Americas",
    "languages": ["English"]
  },
  {
    "name": "United Kingdom",
    "capital": "London",
    "population": 67736000,
    "region": "Europe",
    "languages": ["English"]
  }
]
```

**Example Requests:**
```bash
# Search for countries containing "united"
curl http://localhost:5000/api/countries?search=united

# Search for countries containing "land"
curl http://localhost:5000/api/countries?search=land

# Empty search returns all countries
curl http://localhost:5000/api/countries?search=
```

## Data Model

Each country object contains the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Country name (non-empty) |
| `capital` | string | Capital city name |
| `population` | i64 | Population count (non-negative) |
| `region` | string | Geographic region |
| `languages` | Vec<String> | List of spoken languages |

## Sample Data

The API comes pre-loaded with 196 countries covering five regions:

- **Africa:** 54 countries
- **Americas:** 35 countries
- **Asia:** 48 countries
- **Europe:** 45 countries
- **Oceania:** 14 countries

## Running Tests

The project includes comprehensive test coverage with unit tests, integration tests, and property-based tests.

### Run All Tests

```bash
cargo test
```

### Run Specific Test Files

```bash
# Property-based tests
cargo test --test properties_test

# Data store tests
cargo test --test data_store_test

# API endpoint tests
cargo test --test api_test

# Integration tests
cargo test --test integration_test
```

### Run Tests with Verbose Output

```bash
cargo test -- --nocapture
```

## Testing Strategy

The project uses a dual testing approach:

1. **Unit Tests:** Verify specific examples, edge cases, and error conditions
2. **Property-Based Tests:** Use proptest to verify universal properties across randomly generated inputs

### Property-Based Tests

The following correctness properties are verified:

- **Property 1:** Complete country retrieval - all loaded countries are retrievable
- **Property 2:** Serialization includes all fields
- **Property 3:** Serialization round-trip preserves data
- **Property 4:** Country retrieval by name is case-insensitive
- **Property 5:** Region filtering is case-insensitive and accurate
- **Property 6:** Name search is case-insensitive substring matching
- **Property 7:** Error responses have consistent structure
- **Property 8:** Data validation rejects invalid countries

## Project Structure

```
country-data-api-rust-kiro/
├── src/
│   ├── api/
│   │   ├── mod.rs
│   │   └── routes.rs          # API endpoint definitions
│   ├── models/
│   │   ├── mod.rs
│   │   └── country.rs         # Country data model
│   ├── services/
│   │   ├── mod.rs
│   │   └── country_data_store.rs  # Data storage and retrieval
│   ├── main.rs                # Application entry point
│   ├── lib.rs                 # Library exports
│   └── sample_data.rs         # Sample country data
├── tests/
│   ├── properties_test.rs     # Property-based tests
│   ├── data_store_test.rs     # Data store tests
│   ├── api_test.rs            # API endpoint tests
│   └── integration_test.rs    # Integration tests
├── .kiro/
│   └── specs/
│       └── country-data-api-rust/
│           ├── requirements.md
│           ├── design.md
│           └── tasks.md
├── Cargo.toml                 # Rust dependencies
└── README.md                  # This file
```

## Technology Stack

- **Axum**: Modern, ergonomic web framework
- **Tokio**: Async runtime for Rust
- **Serde**: Serialization/deserialization framework
- **Tower**: Middleware and service abstractions
- **Tracing**: Application-level tracing
- **Proptest**: Property-based testing framework

## Development

### Adding New Countries

To add new countries to the sample data, edit `src/sample_data.rs`:

```rust
Country {
    name: "Your Country".to_string(),
    capital: "Capital City".to_string(),
    population: 1000000,
    region: "Region Name".to_string(),
    languages: vec!["Language1".to_string(), "Language2".to_string()],
}
```

### Building for Production

```bash
cargo build --release
```

The optimized binary will be in `target/release/country-data-api-rust-kiro`

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

## License

This project is provided as-is for educational and demonstration purposes.
