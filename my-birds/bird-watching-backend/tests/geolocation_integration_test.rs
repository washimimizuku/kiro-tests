// Integration test for geolocation feature
// This test validates the complete flow of the geolocation feature:
// 1. Create observation with coordinates
// 2. Validate coordinate storage and retrieval
// 3. Test proximity search
// 4. Test coordinate validation
// 5. Test coordinate updates

use bird_watching_backend::models::observation::{CreateObservationRequest, UpdateObservationRequest};
use bird_watching_backend::models::user::RegisterRequest;
use bird_watching_backend::services::auth_service::AuthService;
use bird_watching_backend::services::observation_service::ObservationService;
use bird_watching_backend::services::geo_service::GeoService;
use chrono::{Duration, Utc};
use sqlx::postgres::PgPoolOptions;
use std::env;
use uuid::Uuid;

// Helper function to get test database pool
async fn get_test_pool() -> sqlx::PgPool {
    let database_url = env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgresql://postgres:password@localhost:5432/bird_watching".to_string()
    });

    PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create test pool")
}

// Helper function to clean up test data
async fn cleanup_user(pool: &sqlx::PgPool, username: &str) {
    let _ = sqlx::query("DELETE FROM users WHERE username = $1")
        .bind(username)
        .execute(pool)
        .await;
}

#[tokio::test]
async fn test_complete_geolocation_flow() {
    let pool = get_test_pool().await;
    let auth_service = AuthService::new(pool.clone());
    let observation_service = ObservationService::new(pool.clone());

    // Generate unique test data
    let uuid_suffix = Uuid::new_v4().to_string().replace("-", "")[..8].to_string();
    let username = format!("testuser_{}", uuid_suffix);
    let email = format!("test_{}@example.com", uuid_suffix);
    let password = "TestPassword123!";

    // Clean up any existing test data
    cleanup_user(&pool, &username).await;

    println!("=== Step 1: Register test user ===");
    let user = auth_service
        .register(RegisterRequest {
            username: username.clone(),
            email: email.clone(),
            password: password.to_string(),
        })
        .await
        .expect("User registration should succeed");
    
    println!("✓ User registered: {} ({})", user.username, user.id);

    // Test coordinates (Central Park, New York)
    let central_park_lat = 40.785091;
    let central_park_lng = -73.968285;

    println!("\n=== Step 2: Create observation with coordinates ===");
    let observation_date = Utc::now() - Duration::days(1);
    let observation = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Northern Cardinal".to_string(),
                observation_date,
                location: "Central Park, New York".to_string(),
                latitude: Some(central_park_lat),
                longitude: Some(central_park_lng),
                notes: Some("Beautiful red bird spotted near the lake".to_string()),
                photo_url: None,
                trip_id: None,
                is_shared: true,
            },
        )
        .await
        .expect("Observation creation with coordinates should succeed");

    println!("✓ Observation created: {}", observation.id);
    println!("  Species: {}", observation.species_name);
    println!("  Location: {}", observation.location);
    println!("  Coordinates: ({}, {})", 
             observation.latitude.unwrap(), 
             observation.longitude.unwrap());

    // Verify coordinates are stored correctly
    assert_eq!(observation.latitude, Some(central_park_lat));
    assert_eq!(observation.longitude, Some(central_park_lng));

    println!("\n=== Step 3: Retrieve observation and verify coordinates persist ===");
    let retrieved = observation_service
        .get_by_id(observation.id)
        .await
        .expect("Observation retrieval should succeed");

    assert_eq!(retrieved.latitude, Some(central_park_lat));
    assert_eq!(retrieved.longitude, Some(central_park_lng));
    println!("✓ Coordinates persisted correctly");

    println!("\n=== Step 4: Create observation without coordinates ===");
    let observation_no_coords = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Blue Jay".to_string(),
                observation_date,
                location: "Somewhere in the park".to_string(),
                latitude: None,
                longitude: None,
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            },
        )
        .await
        .expect("Observation creation without coordinates should succeed");

    assert_eq!(observation_no_coords.latitude, None);
    assert_eq!(observation_no_coords.longitude, None);
    println!("✓ Observation without coordinates created successfully");

    println!("\n=== Step 5: Test coordinate validation - invalid latitude ===");
    let invalid_lat_result = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Invalid Bird".to_string(),
                observation_date,
                location: "Invalid location".to_string(),
                latitude: Some(95.0), // Invalid: > 90
                longitude: Some(-73.0),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            },
        )
        .await;

    assert!(invalid_lat_result.is_err(), "Invalid latitude should be rejected");
    println!("✓ Invalid latitude rejected: {}", invalid_lat_result.unwrap_err());

    println!("\n=== Step 6: Test coordinate validation - invalid longitude ===");
    let invalid_lng_result = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Invalid Bird".to_string(),
                observation_date,
                location: "Invalid location".to_string(),
                latitude: Some(40.0),
                longitude: Some(-185.0), // Invalid: < -180
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            },
        )
        .await;

    assert!(invalid_lng_result.is_err(), "Invalid longitude should be rejected");
    println!("✓ Invalid longitude rejected: {}", invalid_lng_result.unwrap_err());

    println!("\n=== Step 7: Test coordinate validation - incomplete coordinates ===");
    let incomplete_coords_result = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Invalid Bird".to_string(),
                observation_date,
                location: "Invalid location".to_string(),
                latitude: Some(40.0),
                longitude: None, // Missing longitude
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            },
        )
        .await;

    assert!(incomplete_coords_result.is_err(), "Incomplete coordinates should be rejected");
    println!("✓ Incomplete coordinates rejected: {}", incomplete_coords_result.unwrap_err());

    println!("\n=== Step 8: Update observation coordinates ===");
    // Times Square coordinates
    let times_square_lat = 40.758896;
    let times_square_lng = -73.985130;

    let updated = observation_service
        .update(
            observation.id,
            user.id,
            UpdateObservationRequest {
                species_name: None,
                observation_date: None,
                location: Some("Times Square, New York".to_string()),
                latitude: Some(times_square_lat),
                longitude: Some(times_square_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: None,
            },
        )
        .await
        .expect("Observation update should succeed");

    assert_eq!(updated.latitude, Some(times_square_lat));
    assert_eq!(updated.longitude, Some(times_square_lng));
    println!("✓ Coordinates updated successfully");
    println!("  New location: {}", updated.location);
    println!("  New coordinates: ({}, {})", 
             updated.latitude.unwrap(), 
             updated.longitude.unwrap());

    println!("\n=== Step 9: Create additional observations for proximity search ===");
    // Brooklyn Bridge (about 8 km from Times Square)
    let brooklyn_lat = 40.706086;
    let brooklyn_lng = -73.996864;
    
    let obs_brooklyn = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "American Robin".to_string(),
                observation_date,
                location: "Brooklyn Bridge".to_string(),
                latitude: Some(brooklyn_lat),
                longitude: Some(brooklyn_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: true,
            },
        )
        .await
        .expect("Brooklyn observation should be created");

    println!("✓ Brooklyn Bridge observation created");

    // Statue of Liberty (about 10 km from Times Square)
    let liberty_lat = 40.689247;
    let liberty_lng = -74.044502;
    
    let obs_liberty = observation_service
        .create(
            user.id,
            CreateObservationRequest {
                species_name: "Seagull".to_string(),
                observation_date,
                location: "Statue of Liberty".to_string(),
                latitude: Some(liberty_lat),
                longitude: Some(liberty_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: true,
            },
        )
        .await
        .expect("Liberty observation should be created");

    println!("✓ Statue of Liberty observation created");

    println!("\n=== Step 10: Test proximity search (5 km radius from Times Square) ===");
    let nearby_5km = observation_service
        .find_nearby(
            times_square_lat,
            times_square_lng,
            5.0,
            Some(user.id),
            None,
        )
        .await
        .expect("Proximity search should succeed");

    println!("✓ Found {} observations within 5 km", nearby_5km.len());
    for obs_with_dist in &nearby_5km {
        println!("  - {} at {} km: {}", 
                 obs_with_dist.observation.species_name,
                 obs_with_dist.distance_km,
                 obs_with_dist.observation.location);
        
        // Verify distance is within radius
        assert!(obs_with_dist.distance_km <= 5.0, 
                "Distance {} km exceeds radius 5 km", 
                obs_with_dist.distance_km);
        
        // Verify distance field is present and valid
        assert!(obs_with_dist.distance_km >= 0.0);
        assert!(obs_with_dist.distance_km.is_finite());
    }

    // The updated observation (at Times Square) should be found
    let times_square_found = nearby_5km.iter()
        .any(|o| o.observation.id == observation.id);
    assert!(times_square_found, "Times Square observation should be within 5 km");

    println!("\n=== Step 11: Test proximity search (15 km radius from Times Square) ===");
    let nearby_15km = observation_service
        .find_nearby(
            times_square_lat,
            times_square_lng,
            15.0,
            Some(user.id),
            None,
        )
        .await
        .expect("Proximity search should succeed");

    println!("✓ Found {} observations within 15 km", nearby_15km.len());
    
    // All three observations should be found
    assert!(nearby_15km.len() >= 3, "Should find at least 3 observations within 15 km");
    
    let brooklyn_found = nearby_15km.iter()
        .any(|o| o.observation.id == obs_brooklyn.id);
    assert!(brooklyn_found, "Brooklyn observation should be within 15 km");
    
    let liberty_found = nearby_15km.iter()
        .any(|o| o.observation.id == obs_liberty.id);
    assert!(liberty_found, "Liberty observation should be within 15 km");

    println!("\n=== Step 12: Verify Haversine distance calculations ===");
    let calculated_brooklyn_dist = GeoService::haversine_distance(
        times_square_lat, times_square_lng,
        brooklyn_lat, brooklyn_lng
    );
    println!("✓ Distance to Brooklyn Bridge: {:.2} km", calculated_brooklyn_dist);
    assert!(calculated_brooklyn_dist > 0.0);
    assert!(calculated_brooklyn_dist < 15.0);

    let calculated_liberty_dist = GeoService::haversine_distance(
        times_square_lat, times_square_lng,
        liberty_lat, liberty_lng
    );
    println!("✓ Distance to Statue of Liberty: {:.2} km", calculated_liberty_dist);
    assert!(calculated_liberty_dist > 0.0);
    assert!(calculated_liberty_dist < 15.0);

    // Verify distances in search results match calculated distances
    for obs_with_dist in &nearby_15km {
        let expected_dist = GeoService::haversine_distance(
            times_square_lat, times_square_lng,
            obs_with_dist.observation.latitude.unwrap(),
            obs_with_dist.observation.longitude.unwrap()
        );
        
        let diff = (obs_with_dist.distance_km - expected_dist).abs();
        assert!(diff < 0.01, 
                "Distance mismatch for {}: reported={}, calculated={}, diff={}",
                obs_with_dist.observation.species_name,
                obs_with_dist.distance_km,
                expected_dist,
                diff);
    }
    println!("✓ All distance calculations are accurate");

    println!("\n=== Step 13: Test proximity search with species filter ===");
    let cardinal_nearby = observation_service
        .find_nearby(
            times_square_lat,
            times_square_lng,
            15.0,
            Some(user.id),
            Some("Cardinal".to_string()),
        )
        .await
        .expect("Proximity search with filter should succeed");

    println!("✓ Found {} Cardinal observations within 15 km", cardinal_nearby.len());
    
    // Should find the updated observation (Northern Cardinal)
    for obs_with_dist in &cardinal_nearby {
        assert!(obs_with_dist.observation.species_name.contains("Cardinal"),
                "Filtered results should only contain Cardinals");
    }

    println!("\n=== Step 14: Clean up test data ===");
    cleanup_user(&pool, &username).await;
    println!("✓ Test data cleaned up");

    println!("\n=== ✅ All integration tests passed! ===");
    println!("\nTested features:");
    println!("  ✓ User registration");
    println!("  ✓ Observation creation with coordinates");
    println!("  ✓ Observation creation without coordinates");
    println!("  ✓ Coordinate storage and retrieval");
    println!("  ✓ Coordinate validation (latitude bounds)");
    println!("  ✓ Coordinate validation (longitude bounds)");
    println!("  ✓ Coordinate validation (pair requirement)");
    println!("  ✓ Coordinate updates");
    println!("  ✓ Proximity search with various radii");
    println!("  ✓ Distance calculations (Haversine formula)");
    println!("  ✓ Distance inclusion in search results");
    println!("  ✓ Proximity search with species filter");
}
