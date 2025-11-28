"""Property-based tests for Country Data API using Hypothesis."""

from hypothesis import given, strategies as st, settings
from models.country import Country
from services.country_data_store import CountryDataStore
from app import create_app
import pytest


# Custom strategies for generating valid country data
@st.composite
def valid_country(draw):
    """Generate a valid Country instance."""
    name = draw(st.text(min_size=1).filter(lambda x: x.strip()))
    capital = draw(st.text())
    population = draw(st.integers(min_value=0, max_value=10_000_000_000))
    region = draw(st.text())
    languages = draw(st.lists(st.text(), min_size=1))
    
    return Country(
        name=name,
        capital=capital,
        population=population,
        region=region,
        languages=languages
    )


# Feature: country-data-api, Property 2: Serialization includes all fields
@given(country=valid_country())
@settings(max_examples=100)
def test_serialization_includes_all_fields(country):
    """
    For any valid country resource, serializing it to JSON should produce 
    an object containing name, capital, population, region, and languages fields.
    
    Validates: Requirements 1.2, 7.3
    """
    serialized = country.to_dict()
    
    # Check that all required fields are present
    assert 'name' in serialized
    assert 'capital' in serialized
    assert 'population' in serialized
    assert 'region' in serialized
    assert 'languages' in serialized
    
    # Check that the values match the original country
    assert serialized['name'] == country.name
    assert serialized['capital'] == country.capital
    assert serialized['population'] == country.population
    assert serialized['region'] == country.region
    assert serialized['languages'] == country.languages


# Feature: country-data-api, Property 3: Serialization round-trip preserves data
@given(country=valid_country())
@settings(max_examples=100)
def test_serialization_roundtrip(country):
    """
    For any valid country resource, serializing to JSON and then deserializing 
    should produce an equivalent country object with all fields preserved.
    
    Validates: Requirements 7.1, 7.2
    """
    # Serialize then deserialize
    serialized = country.to_dict()
    deserialized = Country.from_dict(serialized)
    
    # Check that all fields are preserved
    assert deserialized.name == country.name
    assert deserialized.capital == country.capital
    assert deserialized.population == country.population
    assert deserialized.region == country.region
    assert deserialized.languages == country.languages
    
    # Check that the objects are equivalent
    assert deserialized == country


# Custom strategies for generating invalid country data
@st.composite
def invalid_country(draw):
    """Generate an invalid Country instance."""
    # Choose which validation rule to violate
    violation_type = draw(st.integers(min_value=0, max_value=2))
    
    if violation_type == 0:
        # Empty or whitespace-only name
        name = draw(st.sampled_from(['', '   ', '\t', '\n']))
        capital = draw(st.text())
        population = draw(st.integers(min_value=0, max_value=10_000_000_000))
        region = draw(st.text())
        languages = draw(st.lists(st.text(), min_size=1))
    elif violation_type == 1:
        # Negative population
        name = draw(st.text(min_size=1).filter(lambda x: x.strip()))
        capital = draw(st.text())
        population = draw(st.integers(max_value=-1))
        region = draw(st.text())
        languages = draw(st.lists(st.text(), min_size=1))
    else:
        # Invalid languages (not a list or contains non-strings)
        name = draw(st.text(min_size=1).filter(lambda x: x.strip()))
        capital = draw(st.text())
        population = draw(st.integers(min_value=0, max_value=10_000_000_000))
        region = draw(st.text())
        # Either not a list, or a list with non-string elements
        if draw(st.booleans()):
            languages = draw(st.integers() | st.text() | st.floats())
        else:
            languages = draw(st.lists(st.integers() | st.floats(), min_size=1))
    
    return Country(
        name=name,
        capital=capital,
        population=population,
        region=region,
        languages=languages
    )


# Feature: country-data-api, Property 8: Data validation rejects invalid countries
@given(country=invalid_country())
@settings(max_examples=100)
def test_data_validation_rejects_invalid_countries(country):
    """
    For any country with invalid data (empty name, negative population, 
    or non-list languages), attempting to validate it should return False.
    
    Validates: Requirements 6.1, 6.2, 6.3
    """
    # Invalid countries should fail validation
    assert country.validate() is False


# Feature: country-data-api, Property 1: Complete country retrieval
@given(countries=st.lists(valid_country(), min_size=0, max_size=20))
@settings(max_examples=100)
def test_complete_country_retrieval(countries):
    """
    For any set of countries loaded into the data store, calling the get all 
    countries endpoint should return exactly that set of countries with all 
    their data intact.
    
    Validates: Requirements 1.1, 1.4
    """
    store = CountryDataStore()
    store.load_countries(countries)
    
    retrieved = store.get_all()
    
    # Should return the same number of countries
    assert len(retrieved) == len(countries)
    
    # All countries should be present with data intact
    for original in countries:
        found = False
        for retrieved_country in retrieved:
            if (retrieved_country.name == original.name and
                retrieved_country.capital == original.capital and
                retrieved_country.population == original.population and
                retrieved_country.region == original.region and
                retrieved_country.languages == original.languages):
                found = True
                break
        assert found, f"Country {original.name} not found in retrieved data"


# Feature: country-data-api, Property 4: Country retrieval by name
@given(countries=st.lists(valid_country(), min_size=1, max_size=20))
@settings(max_examples=100)
def test_country_retrieval_by_name(countries):
    """
    For any country in the data store, requesting that country by its exact 
    name (regardless of case) should return the same country with all 
    attributes intact.
    
    Validates: Requirements 2.1, 2.2, 2.4
    """
    store = CountryDataStore()
    store.load_countries(countries)
    
    # Get all countries actually stored (after validation)
    stored_countries = store.get_all()
    
    if not stored_countries:
        # If no valid countries were stored, nothing to test
        return
    
    # Pick a random country from the stored list
    import random
    target_country = random.choice(stored_countries)
    
    # Test with exact case - get_by_name returns the first match
    retrieved = store.get_by_name(target_country.name)
    assert retrieved is not None
    # The retrieved country should have the same name (case-insensitive)
    assert retrieved.name.casefold() == target_country.name.casefold()
    
    # Verify it's a country from the store with that name
    matching_countries = [c for c in stored_countries if c.name.casefold() == target_country.name.casefold()]
    assert retrieved in matching_countries
    
    # Test with different cases (using casefold for proper Unicode handling)
    retrieved_upper = store.get_by_name(target_country.name.upper())
    assert retrieved_upper is not None
    assert retrieved_upper.name.casefold() == target_country.name.casefold()
    
    retrieved_lower = store.get_by_name(target_country.name.lower())
    assert retrieved_lower is not None
    assert retrieved_lower.name.casefold() == target_country.name.casefold()


# Feature: country-data-api, Property 5: Region filtering is case-insensitive and accurate
@given(countries=st.lists(valid_country(), min_size=0, max_size=20))
@settings(max_examples=100)
def test_region_filtering(countries):
    """
    For any set of countries and any region string, filtering by that region 
    (regardless of case) should return only countries whose region matches 
    (case-insensitive), and should return all such countries.
    
    Validates: Requirements 3.1, 3.2
    """
    store = CountryDataStore()
    store.load_countries(countries)
    
    stored_countries = store.get_all()
    
    if not stored_countries:
        # No countries to test
        return
    
    # Pick a random country and use its region for filtering
    import random
    target_country = random.choice(stored_countries)
    target_region = target_country.region
    
    # Filter by the region
    filtered = store.filter_by_region(target_region)
    
    # All returned countries should match the region (case-insensitive using casefold)
    for country in filtered:
        assert country.region.casefold() == target_region.casefold()
    
    # All countries with matching region should be returned
    expected_count = sum(1 for c in stored_countries if c.region.casefold() == target_region.casefold())
    assert len(filtered) == expected_count
    
    # Test with different cases
    filtered_upper = store.filter_by_region(target_region.upper())
    assert len(filtered_upper) == expected_count
    
    filtered_lower = store.filter_by_region(target_region.lower())
    assert len(filtered_lower) == expected_count


# Feature: country-data-api, Property 6: Name search is case-insensitive substring matching
@given(countries=st.lists(valid_country(), min_size=0, max_size=20), query=st.text())
@settings(max_examples=100)
def test_name_search(countries, query):
    """
    For any set of countries and any search query string, searching by that 
    query (regardless of case) should return all and only countries whose 
    names contain the query as a substring (case-insensitive).
    
    Validates: Requirements 4.1, 4.2
    """
    store = CountryDataStore()
    store.load_countries(countries)
    
    stored_countries = store.get_all()
    
    # Search by the query
    results = store.search_by_name(query)
    
    # If query is empty or whitespace-only, should return all countries
    if not query or not query.strip():
        assert len(results) == len(stored_countries)
        return
    
    # All countries containing the query should be returned (using casefold for proper Unicode handling)
    expected_countries = [c for c in stored_countries if query.casefold() in c.name.casefold()]
    assert len(results) == len(expected_countries), f"Expected {len(expected_countries)} results but got {len(results)} for query '{query}'"
    
    # All returned countries should contain the query (case-insensitive)
    for country in results:
        assert query.casefold() in country.name.casefold(), f"Country '{country.name}' does not contain query '{query}'"
    
    # Verify no countries were missed
    for expected in expected_countries:
        assert expected in results, f"Expected country '{expected.name}' not in results for query '{query}'"
    
    # Test with different cases
    results_upper = store.search_by_name(query.upper())
    assert len(results_upper) == len(expected_countries)
    
    results_lower = store.search_by_name(query.lower())
    assert len(results_lower) == len(expected_countries)



# Feature: country-data-api, Property 7: Error responses have consistent structure
@given(error_type=st.sampled_from(['404', '405']))
@settings(max_examples=100)
def test_error_response_structure(error_type):
    """
    For any error condition (404, 500, 405), the API response should be 
    valid JSON containing an "error" field with a descriptive message.
    
    Validates: Requirements 5.4
    """
    # Create a fresh client for each test
    app = create_app()
    app.config['TESTING'] = True
    client = app.test_client()
    
    response = None
    
    if error_type == '404':
        # Trigger 404 by requesting non-existent country
        response = client.get('/api/countries/NonExistentCountry12345')
    elif error_type == '405':
        # Trigger 405 by using unsupported HTTP method
        response = client.post('/api/countries')
    
    # Check that response is JSON
    assert response.content_type == 'application/json'
    
    # Check that response contains error field
    data = response.get_json()
    assert 'error' in data
    assert isinstance(data['error'], str)
    assert len(data['error']) > 0
