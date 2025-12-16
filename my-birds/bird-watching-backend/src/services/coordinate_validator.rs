use actix_web::{HttpResponse, ResponseError};
use std::fmt;

/// Custom error type for coordinate validation
#[derive(Debug)]
pub enum CoordinateValidationError {
    InvalidLatitude(f64),
    InvalidLongitude(f64),
    IncompleteCoordinates,
}

impl fmt::Display for CoordinateValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CoordinateValidationError::InvalidLatitude(lat) => {
                write!(f, "Latitude must be between -90 and 90 degrees, got: {}", lat)
            }
            CoordinateValidationError::InvalidLongitude(lng) => {
                write!(f, "Longitude must be between -180 and 180 degrees, got: {}", lng)
            }
            CoordinateValidationError::IncompleteCoordinates => {
                write!(f, "Both latitude and longitude must be provided together, or neither")
            }
        }
    }
}

impl ResponseError for CoordinateValidationError {
    fn error_response(&self) -> HttpResponse {
        HttpResponse::BadRequest().json(serde_json::json!({
            "error": self.to_string()
        }))
    }
}

/// Service for validating geographic coordinates
pub struct CoordinateValidator;

impl CoordinateValidator {
    /// Validate latitude is within valid range (-90 to 90)
    pub fn validate_latitude(lat: f64) -> Result<(), CoordinateValidationError> {
        if !lat.is_finite() {
            return Err(CoordinateValidationError::InvalidLatitude(lat));
        }
        
        if lat < -90.0 || lat > 90.0 {
            return Err(CoordinateValidationError::InvalidLatitude(lat));
        }
        
        Ok(())
    }

    /// Validate longitude is within valid range (-180 to 180)
    pub fn validate_longitude(lng: f64) -> Result<(), CoordinateValidationError> {
        if !lng.is_finite() {
            return Err(CoordinateValidationError::InvalidLongitude(lng));
        }
        
        if lng < -180.0 || lng > 180.0 {
            return Err(CoordinateValidationError::InvalidLongitude(lng));
        }
        
        Ok(())
    }

    /// Validate coordinate pair - both must be provided or neither
    /// If both are provided, validates their ranges
    pub fn validate_coordinate_pair(
        latitude: Option<f64>,
        longitude: Option<f64>,
    ) -> Result<(), CoordinateValidationError> {
        match (latitude, longitude) {
            (Some(lat), Some(lng)) => {
                // Both provided - validate ranges
                Self::validate_latitude(lat)?;
                Self::validate_longitude(lng)?;
                Ok(())
            }
            (None, None) => {
                // Neither provided - valid
                Ok(())
            }
            _ => {
                // Only one provided - invalid
                Err(CoordinateValidationError::IncompleteCoordinates)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_latitude() {
        assert!(CoordinateValidator::validate_latitude(0.0).is_ok());
        assert!(CoordinateValidator::validate_latitude(45.0).is_ok());
        assert!(CoordinateValidator::validate_latitude(-45.0).is_ok());
        assert!(CoordinateValidator::validate_latitude(90.0).is_ok());
        assert!(CoordinateValidator::validate_latitude(-90.0).is_ok());
    }

    #[test]
    fn test_invalid_latitude() {
        assert!(CoordinateValidator::validate_latitude(90.1).is_err());
        assert!(CoordinateValidator::validate_latitude(-90.1).is_err());
        assert!(CoordinateValidator::validate_latitude(180.0).is_err());
        assert!(CoordinateValidator::validate_latitude(f64::NAN).is_err());
        assert!(CoordinateValidator::validate_latitude(f64::INFINITY).is_err());
    }

    #[test]
    fn test_valid_longitude() {
        assert!(CoordinateValidator::validate_longitude(0.0).is_ok());
        assert!(CoordinateValidator::validate_longitude(90.0).is_ok());
        assert!(CoordinateValidator::validate_longitude(-90.0).is_ok());
        assert!(CoordinateValidator::validate_longitude(180.0).is_ok());
        assert!(CoordinateValidator::validate_longitude(-180.0).is_ok());
    }

    #[test]
    fn test_invalid_longitude() {
        assert!(CoordinateValidator::validate_longitude(180.1).is_err());
        assert!(CoordinateValidator::validate_longitude(-180.1).is_err());
        assert!(CoordinateValidator::validate_longitude(360.0).is_err());
        assert!(CoordinateValidator::validate_longitude(f64::NAN).is_err());
        assert!(CoordinateValidator::validate_longitude(f64::INFINITY).is_err());
    }

    #[test]
    fn test_valid_coordinate_pairs() {
        // Both provided and valid
        assert!(CoordinateValidator::validate_coordinate_pair(Some(40.7128), Some(-74.0060)).is_ok());
        // Neither provided
        assert!(CoordinateValidator::validate_coordinate_pair(None, None).is_ok());
    }

    #[test]
    fn test_incomplete_coordinates() {
        // Only latitude provided
        assert!(CoordinateValidator::validate_coordinate_pair(Some(40.7128), None).is_err());
        // Only longitude provided
        assert!(CoordinateValidator::validate_coordinate_pair(None, Some(-74.0060)).is_err());
    }

    #[test]
    fn test_invalid_coordinate_pairs() {
        // Invalid latitude
        assert!(CoordinateValidator::validate_coordinate_pair(Some(91.0), Some(-74.0060)).is_err());
        // Invalid longitude
        assert!(CoordinateValidator::validate_coordinate_pair(Some(40.7128), Some(-181.0)).is_err());
    }
}
