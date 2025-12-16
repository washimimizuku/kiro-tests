use bird_watching_backend::models::observation::CreateObservationRequest;
use bird_watching_backend::models::user::RegisterRequest;
use bird_watching_backend::services::auth_service::AuthService;
use bird_watching_backend::services::observation_service::ObservationService;
use chrono::{Duration, Utc};
use proptest::prelude::*;
use proptest::test_runner::TestCaseError;
use sqlx::postgres::PgPoolOptions;
use std::env;
use uuid;

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

// Helper to convert String errors to TestCaseError
fn to_test_error(msg: String) -> TestCaseError {
    TestCaseError::fail(msg)
}

// Strategy for generating valid usernames (with UUID suffix for uniqueness)
fn username_strategy() -> impl Strategy<Value = String> {
    "[a-z][a-z0-9_]{2,10}".prop_map(|s| {
        let uuid_suffix = uuid::Uuid::new_v4().to_string().replace("-", "")[..8].to_string();
        format!("{}_{}", s, uuid_suffix)
    })
}

// Strategy for generating valid emails (with UUID suffix for uniqueness)
fn email_strategy() -> impl Strategy<Value = String> {
    ("[a-z][a-z0-9]{2,10}", "[a-z]{2,10}", "[a-z]{2,3}")
        .prop_map(|(local, domain, tld)| {
            let uuid_suffix = uuid::Uuid::new_v4().to_string().replace("-", "")[..8].to_string();
            format!("{}_{}@{}.{}", local, uuid_suffix, domain, tld)
        })
}

// Strategy for generating valid passwords
fn password_strategy() -> impl Strategy<Value = String> {
    "[a-zA-Z0-9!@#$%^&*]{8,50}".prop_map(|s| s.to_string())
}

// Strategy for generating species names
fn species_strategy() -> impl Strategy<Value = String> {
    "[A-Z][a-z]{3,15} [a-z]{3,15}".prop_map(|s| s.to_string())
}

// Strategy for generating locations
fn location_strategy() -> impl Strategy<Value = String> {
    "[A-Z][a-z]{3,15}, [A-Z]{2}".prop_map(|s| s.to_string())
}

// Strategy for generating valid latitude (-90 to 90)
fn valid_latitude_strategy() -> impl Strategy<Value = f64> {
    (-90.0..=90.0)
}

// Strategy for generating valid longitude (-180 to 180)
fn valid_longitude_strategy() -> impl Strategy<Value = f64> {
    (-180.0..=180.0)
}

// Strategy for generating invalid latitude (outside -90 to 90)
fn invalid_latitude_strategy() -> impl Strategy<Value = f64> {
    prop_oneof![
        (-1000.0..-90.01),
        (90.01..1000.0)
    ]
}

// Strategy for generating invalid longitude (outside -180 to 180)
fn invalid_longitude_strategy() -> impl Strategy<Value = f64> {
    prop_oneof![
        (-1000.0..-180.01),
        (180.01..1000.0)
    ]
}

// Feature: geolocation-map-view, Property 1: Coordinate storage persistence
// **Validates: Requirements 1.1**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_coordinate_storage_persistence(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        latitude in valid_latitude_strategy(),
        longitude in valid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };

            let user_profile = auth_service.register(register_req).await
                .map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;
            let user_id = user_profile.id;

            // Create an observation with coordinates
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: Some(latitude),
                longitude: Some(longitude),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let observation = observation_service.create(user_id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Verify coordinates are stored
            prop_assert_eq!(observation.latitude, Some(latitude), "Latitude should be stored");
            prop_assert_eq!(observation.longitude, Some(longitude), "Longitude should be stored");

            // Retrieve the observation and verify coordinates persist
            let retrieved = observation_service.get_by_id(observation.id).await
                .map_err(|e| to_test_error(format!("Failed to retrieve observation: {}", e)))?;

            prop_assert_eq!(retrieved.latitude, Some(latitude), "Retrieved latitude should match");
            prop_assert_eq!(retrieved.longitude, Some(longitude), "Retrieved longitude should match");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 2: Optional coordinates acceptance
// **Validates: Requirements 1.2**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_optional_coordinates_acceptance(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };

            let user_profile = auth_service.register(register_req).await
                .map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;
            let user_id = user_profile.id;

            // Create an observation without coordinates
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: None,
                longitude: None,
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let observation = observation_service.create(user_id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation without coordinates failed: {}", e)))?;

            // Verify observation was created successfully with null coordinates
            prop_assert_eq!(observation.latitude, None, "Latitude should be None");
            prop_assert_eq!(observation.longitude, None, "Longitude should be None");
            prop_assert!(observation.id.to_string().len() > 0, "Observation should have a valid UUID");

            // Retrieve the observation and verify null coordinates persist
            let retrieved = observation_service.get_by_id(observation.id).await
                .map_err(|e| to_test_error(format!("Failed to retrieve observation: {}", e)))?;

            prop_assert_eq!(retrieved.latitude, None, "Retrieved latitude should be None");
            prop_assert_eq!(retrieved.longitude, None, "Retrieved longitude should be None");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 3: Coordinate update persistence
// **Validates: Requirements 1.3**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_coordinate_update_persistence(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        lat1 in valid_latitude_strategy(),
        lng1 in valid_longitude_strategy(),
        lat2 in valid_latitude_strategy(),
        lng2 in valid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Create an observation with initial coordinates
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: Some(lat1),
                longitude: Some(lng1),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let observation = observation_service.create(user.id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Update the coordinates
            let update_req = bird_watching_backend::models::observation::UpdateObservationRequest {
                species_name: None,
                observation_date: None,
                location: None,
                latitude: Some(lat2),
                longitude: Some(lng2),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: None,
            };

            let updated = observation_service.update(observation.id, user.id, update_req).await
                .map_err(|e| to_test_error(format!("Observation update failed: {}", e)))?;

            // Verify coordinates were updated
            prop_assert_eq!(updated.latitude, Some(lat2), "Latitude should be updated");
            prop_assert_eq!(updated.longitude, Some(lng2), "Longitude should be updated");

            // Retrieve the observation again to verify persistence
            let retrieved = observation_service.get_by_id(observation.id).await
                .map_err(|e| to_test_error(format!("Failed to retrieve observation: {}", e)))?;

            prop_assert_eq!(retrieved.latitude, Some(lat2), "Retrieved latitude should match update");
            prop_assert_eq!(retrieved.longitude, Some(lng2), "Retrieved longitude should match update");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 4: Latitude bounds validation
// **Validates: Requirements 1.4, 9.1**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_latitude_bounds_validation(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        invalid_lat in invalid_latitude_strategy(),
        valid_lng in valid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Try to create an observation with invalid latitude
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: Some(invalid_lat),
                longitude: Some(valid_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let result = observation_service.create(user.id, create_req).await;

            // Creation should fail with validation error
            prop_assert!(result.is_err(), "Creation with invalid latitude should fail");
            let error_msg = result.unwrap_err();
            prop_assert!(error_msg.contains("Latitude") || error_msg.contains("latitude"),
                        "Error should mention latitude: {}", error_msg);

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 5: Longitude bounds validation
// **Validates: Requirements 1.5, 9.2**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_longitude_bounds_validation(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        valid_lat in valid_latitude_strategy(),
        invalid_lng in invalid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Try to create an observation with invalid longitude
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: Some(valid_lat),
                longitude: Some(invalid_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let result = observation_service.create(user.id, create_req).await;

            // Creation should fail with validation error
            prop_assert!(result.is_err(), "Creation with invalid longitude should fail");
            let error_msg = result.unwrap_err();
            prop_assert!(error_msg.contains("Longitude") || error_msg.contains("longitude"),
                        "Error should mention longitude: {}", error_msg);

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 6: Coordinate pair requirement
// **Validates: Requirements 9.3**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_coordinate_pair_requirement(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        coordinate in prop_oneof![
            valid_latitude_strategy().prop_map(|lat| (Some(lat), None)),
            valid_longitude_strategy().prop_map(|lng| (None, Some(lng)))
        ]
    ) {
        let (latitude, longitude) = coordinate;
        
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Try to create an observation with incomplete coordinates
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude,
                longitude,
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let result = observation_service.create(user.id, create_req).await;

            // Creation should fail with validation error
            prop_assert!(result.is_err(), "Creation with incomplete coordinates should fail");
            let error_msg = result.unwrap_err();
            prop_assert!(error_msg.contains("Both") || error_msg.contains("both") || 
                        error_msg.contains("together") || error_msg.contains("neither"),
                        "Error should mention coordinate pair requirement: {}", error_msg);

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 7: Numeric coordinate validation
// **Validates: Requirements 9.4**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_numeric_coordinate_validation(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        non_finite in prop_oneof![
            Just(f64::NAN),
            Just(f64::INFINITY),
            Just(f64::NEG_INFINITY)
        ],
        valid_coord in valid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Try to create an observation with non-finite coordinate
            let observation_date = Utc::now() - Duration::days(1);
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: Some(non_finite),
                longitude: Some(valid_coord),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let result = observation_service.create(user.id, create_req).await;

            // Creation should fail with validation error
            prop_assert!(result.is_err(), "Creation with non-finite coordinate should fail");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 15: Haversine distance calculation
// **Validates: Requirements 8.2**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_haversine_distance_calculation(
        lat1 in valid_latitude_strategy(),
        lng1 in valid_longitude_strategy(),
        lat2 in valid_latitude_strategy(),
        lng2 in valid_longitude_strategy()
    ) {
        use bird_watching_backend::services::geo_service::GeoService;
        
        let result: Result<(), TestCaseError> = (|| {
            let distance = GeoService::haversine_distance(lat1, lng1, lat2, lng2);

            // Property 1: Distance should always be non-negative
            prop_assert!(distance >= 0.0, "Distance should be non-negative, got {}", distance);

            // Property 2: Distance should be finite
            prop_assert!(distance.is_finite(), "Distance should be finite");

            // Property 3: Distance should not exceed half Earth's circumference (~20,015 km)
            // Maximum distance on Earth is from pole to pole
            prop_assert!(distance <= 20100.0, "Distance should not exceed half Earth's circumference, got {}", distance);

            // Property 4: Symmetry - distance(A, B) should equal distance(B, A)
            let reverse_distance = GeoService::haversine_distance(lat2, lng2, lat1, lng1);
            let diff = (distance - reverse_distance).abs();
            prop_assert!(diff < 0.001, "Distance should be symmetric: forward={}, reverse={}, diff={}", 
                        distance, reverse_distance, diff);

            // Property 5: Identity - distance from a point to itself should be 0
            let same_point_distance = GeoService::haversine_distance(lat1, lng1, lat1, lng1);
            prop_assert!(same_point_distance < 0.001, "Distance from point to itself should be ~0, got {}", 
                        same_point_distance);

            // Property 6: Triangle inequality - for any three points A, B, C:
            // distance(A, C) <= distance(A, B) + distance(B, C)
            // Generate a third random point
            let lat3 = (lat1 + lat2) / 2.0; // Midpoint latitude
            let lng3 = (lng1 + lng2) / 2.0; // Midpoint longitude
            
            let dist_ac = GeoService::haversine_distance(lat1, lng1, lat3, lng3);
            let dist_cb = GeoService::haversine_distance(lat3, lng3, lat2, lng2);
            let dist_ab = GeoService::haversine_distance(lat1, lng1, lat2, lng2);
            
            // Allow small tolerance for floating point arithmetic
            prop_assert!(dist_ab <= dist_ac + dist_cb + 0.1, 
                        "Triangle inequality violated: AB={}, AC={}, CB={}", 
                        dist_ab, dist_ac, dist_cb);

            Ok(())
        })();
        result?;
    }
}

// Feature: geolocation-map-view, Property 14: Proximity search radius correctness
// **Validates: Requirements 8.1**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_proximity_search_radius_correctness(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        center_lat in valid_latitude_strategy(),
        center_lng in valid_longitude_strategy(),
        radius_km in 1.0..100.0f64
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Create observations at various distances from center
            let observation_date = Utc::now() - Duration::days(1);
            
            // Observation 1: Very close (should be within radius)
            let close_lat = center_lat + 0.001; // ~111 meters
            let close_lng = center_lng + 0.001;
            let obs1 = observation_service.create(user.id, CreateObservationRequest {
                species_name: "Cardinal".to_string(),
                observation_date,
                location: "Close location".to_string(),
                latitude: Some(close_lat),
                longitude: Some(close_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            }).await.map_err(|e| to_test_error(format!("Failed to create close observation: {}", e)))?;

            // Observation 2: Far away (should be outside radius if radius < distance)
            let far_lat = center_lat + 1.0; // ~111 km
            let far_lng = center_lng + 1.0;
            let obs2 = observation_service.create(user.id, CreateObservationRequest {
                species_name: "Blue Jay".to_string(),
                observation_date,
                location: "Far location".to_string(),
                latitude: Some(far_lat),
                longitude: Some(far_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            }).await.map_err(|e| to_test_error(format!("Failed to create far observation: {}", e)))?;

            // Search for nearby observations
            let nearby = observation_service.find_nearby(
                center_lat,
                center_lng,
                radius_km,
                Some(user.id),
                None,
            ).await.map_err(|e| to_test_error(format!("Proximity search failed: {}", e)))?;

            // Verify all returned observations are within radius
            for obs_with_dist in &nearby {
                prop_assert!(obs_with_dist.distance_km <= radius_km,
                            "Observation {} is at distance {} km, which exceeds radius {} km",
                            obs_with_dist.observation.id, obs_with_dist.distance_km, radius_km);
            }

            // Verify the close observation is included
            let close_found = nearby.iter().any(|o| o.observation.id == obs1.id);
            prop_assert!(close_found, "Close observation should be found in proximity search");

            // Calculate actual distance to far observation
            use bird_watching_backend::services::geo_service::GeoService;
            let far_distance = GeoService::haversine_distance(center_lat, center_lng, far_lat, far_lng);
            
            // Verify far observation is included/excluded correctly based on distance
            let far_found = nearby.iter().any(|o| o.observation.id == obs2.id);
            if far_distance <= radius_km {
                prop_assert!(far_found, "Far observation at {} km should be found when radius is {} km", 
                            far_distance, radius_km);
            } else {
                prop_assert!(!far_found, "Far observation at {} km should not be found when radius is {} km", 
                            far_distance, radius_km);
            }

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}

// Feature: geolocation-map-view, Property 16: Distance inclusion in results
// **Validates: Requirements 8.3**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_distance_inclusion_in_results(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        center_lat in valid_latitude_strategy(),
        center_lng in valid_longitude_strategy(),
        obs_lat in valid_latitude_strategy(),
        obs_lng in valid_longitude_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username).await;

            // Register a user
            let user = auth_service.register(RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("Registration failed: {}", e)))?;

            // Create an observation
            let observation_date = Utc::now() - Duration::days(1);
            let obs = observation_service.create(user.id, CreateObservationRequest {
                species_name: "Cardinal".to_string(),
                observation_date,
                location: "Test location".to_string(),
                latitude: Some(obs_lat),
                longitude: Some(obs_lng),
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            }).await.map_err(|e| to_test_error(format!("Failed to create observation: {}", e)))?;

            // Calculate expected distance
            use bird_watching_backend::services::geo_service::GeoService;
            let expected_distance = GeoService::haversine_distance(center_lat, center_lng, obs_lat, obs_lng);

            // Search with a large radius to ensure we find it
            let nearby = observation_service.find_nearby(
                center_lat,
                center_lng,
                expected_distance + 10.0, // Add buffer
                Some(user.id),
                None,
            ).await.map_err(|e| to_test_error(format!("Proximity search failed: {}", e)))?;

            // Find our observation in results
            let found = nearby.iter().find(|o| o.observation.id == obs.id);
            prop_assert!(found.is_some(), "Observation should be found in proximity search");

            if let Some(obs_with_dist) = found {
                // Verify distance_km field is present and accurate
                prop_assert!(obs_with_dist.distance_km >= 0.0, "Distance should be non-negative");
                prop_assert!(obs_with_dist.distance_km.is_finite(), "Distance should be finite");
                
                // Verify distance matches expected (within 0.1% tolerance)
                let diff = (obs_with_dist.distance_km - expected_distance).abs();
                let tolerance = expected_distance * 0.001;
                prop_assert!(diff <= tolerance,
                            "Distance {} km should match expected {} km (diff: {} km, tolerance: {} km)",
                            obs_with_dist.distance_km, expected_distance, diff, tolerance);
            }

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}
