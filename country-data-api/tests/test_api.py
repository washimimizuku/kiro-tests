"""
Unit tests for API endpoints.
Tests the Flask API routes for country data access.
"""

import pytest
from app import create_app
from models.country import Country


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_get_all_countries_returns_200_and_all_countries(client):
    """Test GET /api/countries returns 200 and all countries."""
    response = client.get('/api/countries')
    
    assert response.status_code == 200
    assert response.content_type == 'application/json'
    
    data = response.get_json()
    assert isinstance(data, list)
    # Sample data has 17 countries
    assert len(data) >= 15
    
    # Verify structure of first country
    if len(data) > 0:
        country = data[0]
        assert 'name' in country
        assert 'capital' in country
        assert 'population' in country
        assert 'region' in country
        assert 'languages' in country


def test_get_country_by_name_returns_200_for_existing_country(client):
    """Test GET /api/countries/<name> returns 200 for existing country."""
    response = client.get('/api/countries/France')
    
    assert response.status_code == 200
    assert response.content_type == 'application/json'
    
    data = response.get_json()
    assert data['name'] == 'France'
    assert data['capital'] == 'Paris'
    assert data['region'] == 'Europe'
    assert 'French' in data['languages']


def test_get_country_by_name_case_insensitive(client):
    """Test GET /api/countries/<name> is case-insensitive."""
    response = client.get('/api/countries/france')
    
    assert response.status_code == 200
    data = response.get_json()
    assert data['name'] == 'France'


def test_get_country_by_name_returns_404_for_nonexistent_country(client):
    """Test GET /api/countries/<name> returns 404 for non-existent country."""
    response = client.get('/api/countries/Atlantis')
    
    assert response.status_code == 404
    assert response.content_type == 'application/json'
    
    data = response.get_json()
    assert 'error' in data
    assert 'Atlantis' in data['error']


def test_region_filtering_returns_correct_subset(client):
    """Test region filtering returns correct subset of countries."""
    response = client.get('/api/countries?region=Europe')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) > 0
    
    # All returned countries should be from Europe
    for country in data:
        assert country['region'] == 'Europe'
    
    # Verify some expected European countries are present
    country_names = [c['name'] for c in data]
    assert 'France' in country_names
    assert 'Germany' in country_names


def test_region_filtering_case_insensitive(client):
    """Test region filtering is case-insensitive."""
    response = client.get('/api/countries?region=europe')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert len(data) > 0
    for country in data:
        assert country['region'] == 'Europe'


def test_region_filtering_returns_empty_for_invalid_region(client):
    """Test region filtering returns empty array for invalid region."""
    response = client.get('/api/countries?region=Narnia')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) == 0


def test_name_search_returns_correct_subset(client):
    """Test name search returns correct subset of countries."""
    response = client.get('/api/countries?search=United')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) > 0
    
    # All returned countries should contain "United" in their name
    for country in data:
        assert 'united' in country['name'].lower()
    
    # Verify expected countries are present
    country_names = [c['name'] for c in data]
    assert 'United States' in country_names
    assert 'United Kingdom' in country_names


def test_name_search_case_insensitive(client):
    """Test name search is case-insensitive."""
    response = client.get('/api/countries?search=united')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert len(data) > 0
    for country in data:
        assert 'united' in country['name'].lower()


def test_name_search_returns_empty_for_no_matches(client):
    """Test name search returns empty array when no countries match."""
    response = client.get('/api/countries?search=Wakanda')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) == 0


def test_name_search_empty_query_returns_all_countries(client):
    """Test name search with empty query returns all countries."""
    response = client.get('/api/countries?search=')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) >= 15


def test_name_search_whitespace_query_returns_all_countries(client):
    """Test name search with whitespace-only query returns all countries."""
    response = client.get('/api/countries?search=   ')
    
    assert response.status_code == 200
    data = response.get_json()
    
    assert isinstance(data, list)
    assert len(data) >= 15



def test_invalid_endpoint_returns_404_with_error_json(client):
    """Test invalid endpoint returns 404 with error JSON."""
    response = client.get('/api/invalid_endpoint')
    
    assert response.status_code == 404
    assert response.content_type == 'application/json'
    
    data = response.get_json()
    assert 'error' in data
    assert isinstance(data['error'], str)


def test_unsupported_http_method_returns_405(client):
    """Test unsupported HTTP method returns 405."""
    # POST is not supported on /api/countries
    response = client.post('/api/countries')
    
    assert response.status_code == 405
    assert response.content_type == 'application/json'
    
    data = response.get_json()
    assert 'error' in data


def test_error_responses_contain_error_field(client):
    """Test error responses contain 'error' field."""
    # Test 404 error
    response_404 = client.get('/api/countries/NonExistentCountry')
    data_404 = response_404.get_json()
    assert 'error' in data_404
    assert isinstance(data_404['error'], str)
    assert len(data_404['error']) > 0
    
    # Test 405 error
    response_405 = client.post('/api/countries')
    data_405 = response_405.get_json()
    assert 'error' in data_405
    assert isinstance(data_405['error'], str)
    assert len(data_405['error']) > 0
    
    # Test 404 for invalid endpoint
    response_invalid = client.get('/api/invalid')
    data_invalid = response_invalid.get_json()
    assert 'error' in data_invalid
    assert isinstance(data_invalid['error'], str)
    assert len(data_invalid['error']) > 0
