# Country Data API - Rust

A RESTful API built with Axum that provides access to country information including names, capitals, populations, regions, and languages.

This is a Rust implementation of the Python Flask Country Data API, providing the same functionality with improved performance and type safety.

## Features

- Retrieve all countries
- Get specific country by name
- Filter countries by region
- Search countries by name (substring matching)
- Case-insensitive queries
- Async/await with Tokio runtime
- Type-safe with Rust's type system

## Requirements

- Rust 1.70+ (with Cargo)

## Installation

1. Navigate to the project directory:
```bash
cd country-data-api-rust
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
    "population": 67391582,
    "region": "Europe",
    "languages": ["French"]
  },
  {
    "name": "Japan",
    "capital": "Tokyo",
    "population": 125836021,
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
  "population": 67391582,
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
    "population": 67391582,
    "region": "Europe",
    "languages": ["French"]
  },
  {
    "name": "Germany",
    "capital": "Berlin",
    "population": 83240525,
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
    "population": 331002651,
    "region": "Americas",
    "languages": ["English", "Spanish"]
  },
  {
    "name": "United Kingdom",
    "capital": "London",
    "population": 67886011,
    "region": "Europe",
    "languages": ["English", "Welsh", "Scottish Gaelic"]
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

The API comes pre-loaded with 17 countries covering five regions:

- **Europe:** France, Germany, Spain, Italy, United Kingdom
- **Asia:** Japan, China, India, Thailand
- **Americas:** United States, Canada, Brazil, Mexico
- **Africa:** Egypt, South Africa
- **Oceania:** Australia, New Zealand

## Project Structure

```
country-data-api-rust/
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
│   └── sample_data.rs         # Sample country data
├── Cargo.toml                 # Rust dependencies
└── README.md                  # This file
```

## Technology Stack

- **Axum**: Modern, ergonomic web framework
- **Tokio**: Async runtime for Rust
- **Serde**: Serialization/deserialization framework
- **Tower**: Middleware and service abstractions
- **Tracing**: Application-level tracing

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

The optimized binary will be in `target/release/country-data-api-rust`

### Running Tests

```bash
cargo test
```

## Differences from Python Version

- **Performance**: Significantly faster due to Rust's compiled nature and zero-cost abstractions
- **Type Safety**: Compile-time type checking prevents many runtime errors
- **Concurrency**: Built-in async/await with Tokio for efficient concurrent request handling
- **Memory Safety**: No garbage collector, but guaranteed memory safety through Rust's ownership system
- **Binary Size**: Single compiled binary with no runtime dependencies

## License

This project is provided as-is for educational and demonstration purposes.
