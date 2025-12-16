# Country Data API

A RESTful API built with Flask that provides access to country information including names, capitals, populations, regions, and languages.

## Features

- Retrieve all countries
- Get specific country by name
- Filter countries by region
- Search countries by name (substring matching)
- Case-insensitive queries
- Comprehensive error handling
- Property-based testing with Hypothesis

## Requirements

- Python 3.7+
- Flask 3.0.0
- Hypothesis 6.92.0 (for testing)

## Installation

1. Clone the repository or navigate to the project directory:
```bash
cd country-data-api
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Running the Application

Start the Flask development server:

```bash
python app.py
```

The API will be available at `http://localhost:5000`

## API Documentation

### OpenAPI Specification

The API is fully documented using OpenAPI 3.0 specification. You can find the complete API specification in `openapi.yaml`.

To view the API documentation in a user-friendly format, you can use tools like:
- [Swagger Editor](https://editor.swagger.io/) - Paste the contents of `openapi.yaml`
- [Swagger UI](https://swagger.io/tools/swagger-ui/) - Host the specification locally
- [Redoc](https://github.com/Redocly/redoc) - Generate beautiful API documentation

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

# Whitespace-only search returns all countries
curl "http://localhost:5000/api/countries?search=%20"
```

## Error Handling

The API returns consistent JSON error responses for various error conditions:

### 404 Not Found
Returned when a country is not found or an invalid endpoint is accessed.

```json
{
  "error": "Country \"InvalidName\" not found"
}
```

### 405 Method Not Allowed
Returned when an unsupported HTTP method is used.

```json
{
  "error": "Method not allowed"
}
```

### 500 Internal Server Error
Returned when an unexpected server error occurs.

```json
{
  "error": "Internal server error"
}
```

## Data Model

Each country object contains the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Country name (non-empty) |
| `capital` | string | Capital city name |
| `population` | integer | Population count (non-negative) |
| `region` | string | Geographic region |
| `languages` | array | List of spoken languages |

## Sample Data

The API comes pre-loaded with 17 countries covering five regions:

- **Europe:** France, Germany, Spain, Italy, United Kingdom
- **Asia:** Japan, China, India, Thailand
- **Americas:** United States, Canada, Brazil, Mexico
- **Africa:** Egypt, South Africa
- **Oceania:** Australia, New Zealand

## Running Tests

The project includes comprehensive test coverage with unit tests, integration tests, and property-based tests.

### Run All Tests

```bash
pytest
```

### Run Specific Test Files

```bash
# Unit tests for data store
pytest tests/test_data_store.py

# Unit tests for API routes
pytest tests/test_api.py

# Integration tests
pytest tests/test_integration.py

# Property-based tests
pytest tests/test_properties.py
```

### Run Tests with Verbose Output

```bash
pytest -v
```

### Run Tests with Coverage Report

```bash
pytest --cov=. --cov-report=html
```

## Testing Strategy

The project uses a dual testing approach:

1. **Unit Tests:** Verify specific examples, edge cases, and error conditions
2. **Property-Based Tests:** Use Hypothesis to verify universal properties across randomly generated inputs

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
country-data-api/
├── api/
│   ├── __init__.py
│   └── routes.py          # API endpoint definitions
├── models/
│   ├── __init__.py
│   └── country.py         # Country data model
├── services/
│   ├── __init__.py
│   └── country_data_store.py  # Data storage and retrieval
├── tests/
│   ├── __init__.py
│   ├── test_api.py        # API endpoint tests
│   ├── test_data_store.py # Data store tests
│   ├── test_integration.py # Integration tests
│   └── test_properties.py # Property-based tests
├── app.py                 # Application entry point
├── sample_data.py         # Sample country data
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## Development

### Adding New Countries

To add new countries to the sample data, edit `sample_data.py`:

```python
Country(
    name="Your Country",
    capital="Capital City",
    population=1000000,
    region="Region Name",
    languages=["Language1", "Language2"]
)
```

### Extending the API

To add new endpoints:

1. Add route handlers in `api/routes.py`
2. Add corresponding tests in `tests/test_api.py`
3. Update this README with the new endpoint documentation

## License

This project is provided as-is for educational and demonstration purposes.

## Contributing

Contributions are welcome! Please ensure all tests pass before submitting changes:

```bash
pytest
```
