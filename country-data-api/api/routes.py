"""
API Routes for Country Data API.
Implements REST endpoints for country data access.
"""

from flask import Blueprint, jsonify, request
from services.country_data_store import CountryDataStore


# Create blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Global data store instance (will be set during app initialization)
data_store: CountryDataStore = None


def init_routes(store: CountryDataStore):
    """Initialize routes with the data store instance.
    
    Args:
        store: The CountryDataStore instance to use for data access
    """
    global data_store
    data_store = store


@api_bp.route('/countries', methods=['GET'])
def get_countries():
    """Get all countries or filter by region/search query.
    
    Query Parameters:
        region: Filter countries by region (case-insensitive)
        search: Search countries by partial name match (case-insensitive)
    
    Returns:
        JSON array of country objects with 200 status code
    """
    try:
        # Check for region filter
        region = request.args.get('region')
        if region:
            countries = data_store.filter_by_region(region)
            return jsonify([country.to_dict() for country in countries]), 200
        
        # Check for search query
        search_query = request.args.get('search')
        if search_query is not None:  # Allow empty string
            countries = data_store.search_by_name(search_query)
            return jsonify([country.to_dict() for country in countries]), 200
        
        # Return all countries
        countries = data_store.get_all()
        return jsonify([country.to_dict() for country in countries]), 200
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500


@api_bp.route('/countries/<name>', methods=['GET'])
def get_country_by_name(name: str):
    """Get a specific country by name.
    
    Args:
        name: The name of the country to retrieve (case-insensitive)
    
    Returns:
        JSON object of the country with 200 status code, or
        JSON error object with 404 status code if not found
    """
    try:
        country = data_store.get_by_name(name)
        
        if country is None:
            return jsonify({'error': f'Country "{name}" not found'}), 404
        
        return jsonify(country.to_dict()), 200
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500
