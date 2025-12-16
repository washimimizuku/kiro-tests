"""
Integration tests for Country Data API.
Tests the full application startup, data loading, and complete request flows.
"""

import pytest
from app import create_app
from sample_data import get_sample_countries


@pytest.fixture
def app():
    """Create and configure the Flask application for testing."""
    app = create_app()
    app.config['TESTING'] = True
    return app


@pytest.fixture
def client(app):
    """Create a test client for the Flask application."""
    with app.test_client() as client:
        yield client


class TestApplicationStartup:
    """Test full application startup with sample data."""
    
    def test_app_initializes_successfully(self, app):
        """Test that the application initializes without errors."""
        assert app is not None
        assert app.config['TESTING'] is True
    
    def test_sample_data_loads_on_startup(self, client):
        """Test that sample data is loaded when the application starts."""
        response = client.get('/api/countries')
        assert response.status_code == 200
        
        data = response.get_json()
        assert isinstance(data, list)
        
        # Verify we have the expected number of countries from sample data
        sample_countries = get_sample_countries()
        assert len(data) == len(sample_countries)
    
    def test_all_sample_countries_are_accessible(self, client):
        """Test that all sample countries can be retrieved individually."""
        try:
            sample_countries = get_sample_countries()
            
            for country in sample_countries:
                response = client.get(f'/api/countries/{country.name}')
                assert response.status_code == 200
                
                data = response.get_json()
                assert data['name'] == country.name
                assert data['capital'] == country.capital
                assert data['population'] == country.population
                assert data['region'] == country.region
                assert data['languages'] == country.languages
        except Exception as e:
            pytest.fail(f"Failed to access sample countries: {e}")


class TestEndpointsWorkTogether:
    """Test that all endpoints work together correctly."""
    
    def test_list_filter_and_retrieve_workflow(self, client):
        """Test a complete workflow: list all, filter by region, retrieve specific country."""
        try:
            # Step 1: List all countries
            response = client.get('/api/countries')
            assert response.status_code == 200
            all_countries = response.get_json()
            assert len(all_countries) > 0
            
            # Step 2: Filter by a specific region
            response = client.get('/api/countries?region=Europe')
            assert response.status_code == 200
            european_countries = response.get_json()
            assert len(european_countries) > 0
            assert len(european_countries) < len(all_countries)
            
            # Verify all returned countries are from Europe
            for country in european_countries:
                assert country['region'] == 'Europe'
            
            # Step 3: Retrieve a specific European country
            first_european = european_countries[0]
            response = client.get(f'/api/countries/{first_european["name"]}')
            assert response.status_code == 200
            
            retrieved_country = response.get_json()
            assert retrieved_country['name'] == first_european['name']
            assert retrieved_country['region'] == 'Europe'
        except Exception as e:
            pytest.fail(f"List, filter, and retrieve workflow failed: {e}")
    
    def test_search_and_retrieve_workflow(self, client):
        """Test searching for countries and then retrieving them individually."""
        try:
            # Step 1: Search for countries containing "United"
            response = client.get('/api/countries?search=United')
            assert response.status_code == 200
            search_results = response.get_json()
            assert len(search_results) > 0
            
            # Verify all results contain "United" in the name
            for country in search_results:
                assert 'united' in country['name'].lower()
            
            # Step 2: Retrieve each found country individually
            for country in search_results:
                response = client.get(f'/api/countries/{country["name"]}')
                assert response.status_code == 200
                
                retrieved = response.get_json()
                assert retrieved['name'] == country['name']
                assert retrieved['capital'] == country['capital']
        except Exception as e:
            pytest.fail(f"Search and retrieve workflow failed: {e}")
    
    def test_multiple_regions_can_be_queried(self, client):
        """Test that different regions can be queried and return different results."""
        try:
            regions = ['Europe', 'Asia', 'Americas', 'Africa', 'Oceania']
            region_results = {}
            
            for region in regions:
                response = client.get(f'/api/countries?region={region}')
                assert response.status_code == 200
                
                countries = response.get_json()
                region_results[region] = countries
                
                # Verify all countries in this region match
                for country in countries:
                    assert country['region'] == region
            
            # Verify we got different results for different regions
            assert len(region_results['Europe']) > 0
            assert len(region_results['Asia']) > 0
            
            # Verify no overlap between regions
            europe_names = {c['name'] for c in region_results['Europe']}
            asia_names = {c['name'] for c in region_results['Asia']}
            assert len(europe_names.intersection(asia_names)) == 0
        except Exception as e:
            pytest.fail(f"Multiple regions query failed: {e}")


class TestErrorHandlingInCompleteFlow:
    """Test error handling in complete request flows."""
    
    def _assert_error_response(self, response, expected_status):
        """Helper to assert error response structure."""
        assert response.status_code == expected_status
        assert response.content_type == 'application/json'
        error_data = response.get_json()
        assert 'error' in error_data
        assert isinstance(error_data['error'], str)
        return error_data
    
    def test_404_error_flow_for_nonexistent_country(self, client):
        """Test complete error flow when requesting a non-existent country."""
        # First verify the country doesn't exist in the list
        response = client.get('/api/countries')
        assert response.status_code == 200
        all_countries = response.get_json()
        country_names = [c['name'] for c in all_countries]
        assert 'Atlantis' not in country_names
        
        # Now try to retrieve it and verify proper error handling
        response = client.get('/api/countries/Atlantis')
        error_data = self._assert_error_response(response, 404)
        assert 'Atlantis' in error_data['error']
    
    def test_404_error_flow_for_invalid_endpoint(self, client):
        """Test error handling for completely invalid endpoints."""
        response = client.get('/api/invalid_endpoint')
        self._assert_error_response(response, 404)
    
    def test_405_error_flow_for_unsupported_methods(self, client):
        """Test error handling for unsupported HTTP methods."""
        # Test POST on countries list endpoint
        response = client.post('/api/countries')
        self._assert_error_response(response, 405)
        
        # Test PUT on specific country endpoint
        response = client.put('/api/countries/France')
        self._assert_error_response(response, 405)
        
        # Test DELETE on countries list endpoint
        response = client.delete('/api/countries')
        self._assert_error_response(response, 405)
    
    def test_error_responses_are_consistent_across_endpoints(self, client):
        """Test that error responses have consistent structure across all endpoints."""
        # Collect error responses from different scenarios
        errors = []
        
        # 404 from non-existent country
        response = client.get('/api/countries/NonExistent')
        errors.append(response.get_json())
        
        # 404 from invalid endpoint
        response = client.get('/api/invalid')
        errors.append(response.get_json())
        
        # 405 from unsupported method
        response = client.post('/api/countries')
        errors.append(response.get_json())
        
        # Verify all have the same structure
        for error in errors:
            assert isinstance(error, dict)
            assert 'error' in error
            assert isinstance(error['error'], str)
            assert len(error['error']) > 0


class TestDataIntegrity:
    """Test data integrity across the full application."""
    
    def test_all_countries_have_required_fields(self, client):
        """Test that all countries returned by the API have all required fields."""
        response = client.get('/api/countries')
        assert response.status_code == 200
        
        countries = response.get_json()
        required_fields = ['name', 'capital', 'population', 'region', 'languages']
        
        for country in countries:
            for field in required_fields:
                assert field in country, f"Country {country.get('name', 'unknown')} missing field: {field}"
            
            # Verify field types
            assert isinstance(country['name'], str)
            assert isinstance(country['capital'], str)
            assert isinstance(country['population'], int)
            assert isinstance(country['region'], str)
            assert isinstance(country['languages'], list)
            
            # Verify data constraints
            assert len(country['name']) > 0
            assert country['population'] >= 0
            assert len(country['languages']) > 0
    
    def test_country_data_consistency_across_endpoints(self, client):
        """Test that country data is consistent when accessed through different endpoints."""
        # Get all countries
        response = client.get('/api/countries')
        all_countries = response.get_json()
        
        # Pick a country and verify it's consistent across different access methods
        test_country = all_countries[0]
        country_name = test_country['name']
        country_region = test_country['region']
        
        # Access via direct name lookup
        response = client.get(f'/api/countries/{country_name}')
        direct_lookup = response.get_json()
        assert direct_lookup == test_country
        
        # Access via region filter
        response = client.get(f'/api/countries?region={country_region}')
        region_results = response.get_json()
        matching_countries = [c for c in region_results if c['name'] == country_name]
        assert len(matching_countries) == 1
        assert matching_countries[0] == test_country
        
        # Access via name search
        response = client.get(f'/api/countries?search={country_name[:3]}')
        search_results = response.get_json()
        matching_countries = [c for c in search_results if c['name'] == country_name]
        assert len(matching_countries) == 1
        assert matching_countries[0] == test_country
