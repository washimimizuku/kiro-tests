from dataclasses import dataclass
from typing import List, Dict, Any


@dataclass
class Country:
    """Represents a country with its attributes."""
    name: str
    capital: str
    population: int
    region: str
    languages: List[str]
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize country to dictionary for JSON serialization.
        
        Returns:
            Dictionary containing all country fields
        """
        return {
            'name': self.name,
            'capital': self.capital,
            'population': self.population,
            'region': self.region,
            'languages': self.languages
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Country':
        """Deserialize country from dictionary.
        
        Args:
            data: Dictionary containing country data
            
        Returns:
            Country instance
        """
        return cls(
            name=data['name'],
            capital=data['capital'],
            population=data['population'],
            region=data['region'],
            languages=data['languages']
        )
    
    def validate(self) -> bool:
        """Validate country data integrity.
        
        Returns:
            True if data is valid, False otherwise
        """
        # Check name is non-empty
        if not self.name or not isinstance(self.name, str) or not self.name.strip():
            return False
        
        # Check population is non-negative integer
        if not isinstance(self.population, int) or self.population < 0:
            return False
        
        # Check languages is a list of strings
        if not isinstance(self.languages, list):
            return False
        
        for lang in self.languages:
            if not isinstance(lang, str):
                return False
        
        return True
