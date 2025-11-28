/// Service for geographic calculations
pub struct GeoService;

impl GeoService {
    /// Calculate the great-circle distance between two points on Earth using the Haversine formula
    /// 
    /// # Arguments
    /// * `lat1` - Latitude of first point in decimal degrees
    /// * `lng1` - Longitude of first point in decimal degrees
    /// * `lat2` - Latitude of second point in decimal degrees
    /// * `lng2` - Longitude of second point in decimal degrees
    /// 
    /// # Returns
    /// Distance in kilometers
    /// 
    /// # Formula
    /// The Haversine formula:
    /// a = sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)
    /// c = 2 * atan2(√a, √(1−a))
    /// d = R * c
    /// 
    /// where φ is latitude, λ is longitude, R is earth's radius (6371 km)
    pub fn haversine_distance(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
        const EARTH_RADIUS_KM: f64 = 6371.0;

        // Convert degrees to radians
        let lat1_rad = lat1.to_radians();
        let lat2_rad = lat2.to_radians();
        let delta_lat = (lat2 - lat1).to_radians();
        let delta_lng = (lng2 - lng1).to_radians();

        // Haversine formula
        let a = (delta_lat / 2.0).sin().powi(2)
            + lat1_rad.cos() * lat2_rad.cos() * (delta_lng / 2.0).sin().powi(2);

        let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());

        EARTH_RADIUS_KM * c
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_haversine_same_point() {
        let distance = GeoService::haversine_distance(40.7128, -74.0060, 40.7128, -74.0060);
        assert!(distance < 0.001, "Distance between same point should be ~0");
    }

    #[test]
    fn test_haversine_new_york_to_london() {
        // New York: 40.7128° N, 74.0060° W
        // London: 51.5074° N, 0.1278° W
        let distance = GeoService::haversine_distance(40.7128, -74.0060, 51.5074, -0.1278);
        
        // Expected distance is approximately 5570 km
        // Allow 1% tolerance
        assert!(
            (distance - 5570.0).abs() < 56.0,
            "Distance from New York to London should be ~5570 km, got {}",
            distance
        );
    }

    #[test]
    fn test_haversine_sydney_to_tokyo() {
        // Sydney: 33.8688° S, 151.2093° E
        // Tokyo: 35.6762° N, 139.6503° E
        let distance = GeoService::haversine_distance(-33.8688, 151.2093, 35.6762, 139.6503);
        
        // Expected distance is approximately 7820 km
        // Allow 1% tolerance
        assert!(
            (distance - 7820.0).abs() < 78.0,
            "Distance from Sydney to Tokyo should be ~7820 km, got {}",
            distance
        );
    }

    #[test]
    fn test_haversine_equator() {
        // Two points on the equator, 1 degree apart
        // At equator, 1 degree longitude ≈ 111 km
        let distance = GeoService::haversine_distance(0.0, 0.0, 0.0, 1.0);
        
        assert!(
            (distance - 111.0).abs() < 2.0,
            "Distance of 1 degree at equator should be ~111 km, got {}",
            distance
        );
    }

    #[test]
    fn test_haversine_poles() {
        // North pole to South pole (through 0° longitude)
        let distance = GeoService::haversine_distance(90.0, 0.0, -90.0, 0.0);
        
        // Half the Earth's circumference ≈ 20,015 km
        assert!(
            (distance - 20015.0).abs() < 200.0,
            "Distance from North to South pole should be ~20,015 km, got {}",
            distance
        );
    }

    #[test]
    fn test_haversine_date_line_crossing() {
        // Two points near the International Date Line
        // 179° E to 179° W (should be 2° apart, not 358°)
        let distance = GeoService::haversine_distance(0.0, 179.0, 0.0, -179.0);
        
        // 2 degrees at equator ≈ 222 km
        assert!(
            (distance - 222.0).abs() < 5.0,
            "Distance across date line should be ~222 km, got {}",
            distance
        );
    }

    #[test]
    fn test_haversine_short_distance() {
        // Two points very close together (1 km apart at equator)
        // 1 km ≈ 0.009 degrees at equator
        let distance = GeoService::haversine_distance(0.0, 0.0, 0.0, 0.009);
        
        assert!(
            (distance - 1.0).abs() < 0.1,
            "Distance should be ~1 km, got {}",
            distance
        );
    }
}
