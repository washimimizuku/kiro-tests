"""
Country Data API - Main Application Entry Point

This is the main entry point for the Country Data API Flask application.
"""

from flask import Flask, jsonify
from services.country_data_store import CountryDataStore
from sample_data import get_sample_countries
from api.routes import api_bp, init_routes
import logging


# Configure logging
logging.basicConfig(level=logging.INFO)


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    # Initialize data store and load sample data
    data_store = CountryDataStore()
    data_store.load_countries(get_sample_countries())
    
    # Initialize routes with data store
    init_routes(data_store)
    
    # Register API routes
    app.register_blueprint(api_bp)
    
    # Register error handlers
    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors."""
        return jsonify({'error': 'Resource not found'}), 404
    
    @app.errorhandler(405)
    def method_not_allowed(error):
        """Handle 405 errors."""
        return jsonify({'error': 'Method not allowed'}), 405
    
    @app.errorhandler(500)
    def internal_error(error):
        """Handle 500 errors."""
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)
