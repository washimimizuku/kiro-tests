"""Country Data Store - In-memory storage for country data."""

from typing import List, Optional
import logging
from models.country import Country


logger = logging.getLogger(__name__)


class CountryDataStore:
    """In-memory data store for country information."""
    
    def __init__(self):
        """Initialize an empty country data store."""
        self.countries: List[Country] = []
    
    def load_countries(self, countries: List[Country]) -> None:
        """Load and validate country data into the store.
        
        Args:
            countries: List of Country instances to load
            
        Note:
            Invalid countries are rejected and logged as errors.
        """
        self.countries = []
        for country in countries:
            try:
                if country.validate():
                    self.countries.append(country)
                else:
                    logger.error(f"Invalid country data rejected: {country.name if hasattr(country, 'name') else 'Unknown'}")
            except Exception as e:
                logger.error(f"Error validating country: {type(e).__name__}")
                continue
    
    def get_all(self) -> List[Country]:
        """Retrieve all countries from the store.
        
        Returns:
            List of all Country instances in the store
        """
        return self.countries.copy()
    
    def get_by_name(self, name: str) -> Optional[Country]:
        """Retrieve a country by name with case-insensitive matching.
        
        Args:
            name: The name of the country to retrieve
            
        Returns:
            The matching Country instance, or None if not found
        """
        try:
            name_folded = name.casefold()
            for country in self.countries:
                if country.name.casefold() == name_folded:
                    return country
            return None
        except (AttributeError, TypeError) as e:
            logger.error(f"Error in get_by_name: {type(e).__name__}")
            return None
    
    def filter_by_region(self, region: str) -> List[Country]:
        """Filter countries by region with case-insensitive matching.
        
        Args:
            region: The region to filter by
            
        Returns:
            List of Country instances matching the specified region
        """
        try:
            region_folded = region.casefold()
            return [
                country for country in self.countries
                if country.region.casefold() == region_folded
            ]
        except (AttributeError, TypeError) as e:
            logger.error(f"Error in filter_by_region: {type(e).__name__}")
            return []
    
    def search_by_name(self, query: str) -> List[Country]:
        """Search countries by partial name match with case-insensitive substring matching.
        
        Args:
            query: The search query string
            
        Returns:
            List of Country instances whose names contain the query string
        """
        try:
            # Empty or whitespace-only query returns all countries
            if not query or not query.strip():
                return self.countries.copy()
            
            query_folded = query.casefold()
            return [
                country for country in self.countries
                if query_folded in country.name.casefold()
            ]
        except (AttributeError, TypeError) as e:
            logger.error(f"Error in search_by_name: {type(e).__name__}")
            return []
