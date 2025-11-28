"""Unit tests for CountryDataStore edge cases."""

import pytest
from models.country import Country
from services.country_data_store import CountryDataStore


def test_empty_data_store_returns_empty_array():
    """Test that an empty data store returns an empty array."""
    store = CountryDataStore()
    
    assert store.get_all() == []


def test_non_existent_country_returns_none():
    """Test that requesting a non-existent country returns None."""
    store = CountryDataStore()
    
    # Load some sample countries
    countries = [
        Country(name="France", capital="Paris", population=67000000, region="Europe", languages=["French"]),
        Country(name="Japan", capital="Tokyo", population=126000000, region="Asia", languages=["Japanese"])
    ]
    store.load_countries(countries)
    
    # Request a country that doesn't exist
    result = store.get_by_name("Atlantis")
    assert result is None


def test_empty_region_filter_returns_empty_array():
    """Test that filtering by a non-matching region returns an empty array."""
    store = CountryDataStore()
    
    # Load some sample countries
    countries = [
        Country(name="France", capital="Paris", population=67000000, region="Europe", languages=["French"]),
        Country(name="Japan", capital="Tokyo", population=126000000, region="Asia", languages=["Japanese"])
    ]
    store.load_countries(countries)
    
    # Filter by a region that doesn't exist
    result = store.filter_by_region("Antarctica")
    assert result == []


def test_empty_search_query_returns_all_countries():
    """Test that an empty search query returns all countries."""
    store = CountryDataStore()
    
    # Load some sample countries
    countries = [
        Country(name="France", capital="Paris", population=67000000, region="Europe", languages=["French"]),
        Country(name="Japan", capital="Tokyo", population=126000000, region="Asia", languages=["Japanese"]),
        Country(name="Brazil", capital="Brasilia", population=212000000, region="Americas", languages=["Portuguese"])
    ]
    store.load_countries(countries)
    
    # Search with empty query
    result = store.search_by_name("")
    assert len(result) == 3
    assert all(c in result for c in countries)


def test_whitespace_only_search_query_returns_all_countries():
    """Test that a whitespace-only search query returns all countries."""
    store = CountryDataStore()
    
    # Load some sample countries
    countries = [
        Country(name="France", capital="Paris", population=67000000, region="Europe", languages=["French"]),
        Country(name="Japan", capital="Tokyo", population=126000000, region="Asia", languages=["Japanese"]),
        Country(name="Brazil", capital="Brasilia", population=212000000, region="Americas", languages=["Portuguese"])
    ]
    store.load_countries(countries)
    
    # Search with whitespace-only queries
    result_spaces = store.search_by_name("   ")
    assert len(result_spaces) == 3
    
    result_tabs = store.search_by_name("\t\t")
    assert len(result_tabs) == 3
    
    result_mixed = store.search_by_name(" \t \n ")
    assert len(result_mixed) == 3
