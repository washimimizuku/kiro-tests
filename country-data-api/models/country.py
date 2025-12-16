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
            
        Raises:
            KeyError: If required keys are missing
            ValueError: If data types are invalid
        """
        try:
            return cls(
                name=data['name'],
                capital=data['capital'],
                population=data['population'],
                region=data['region'],
                languages=data['languages']
            )
        except KeyError as e:
            raise KeyError(f"Missing required field: {e}")
        except (TypeError, ValueError) as e:
            raise ValueError(f"Invalid data type: {e}")
    
    def validate(self) -> bool:
        """Validate country data integrity.
        
        Returns:
            True if data is valid, False otherwise
        """
        return (self._is_valid_name() and 
                self._is_valid_population() and 
                self._is_valid_languages())
    
    def _is_valid_name(self) -> bool:
        """Check if name is valid."""
        return (isinstance(self.name, str) and 
                self.name and 
                self.name.strip())
    
    def _is_valid_population(self) -> bool:
        """Check if population is valid."""
        return isinstance(self.population, int) and self.population >= 0
    
    def _is_valid_languages(self) -> bool:
        """Check if languages list is valid."""
        return (isinstance(self.languages, list) and 
                all(isinstance(lang, str) for lang in self.languages))
