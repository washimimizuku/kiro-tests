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

// Strategy for generating valid usernames (with UUID suffix for uniqueness in parallel tests)
fn username_strategy() -> impl Strategy<Value = String> {
    "[a-z][a-z0-9_]{2,10}".prop_map(|s| {
        let uuid_suffix = uuid::Uuid::new_v4().to_string().replace("-", "")[..8].to_string();
        format!("{}_{}", s, uuid_suffix)
    })
}

// Strategy for generating valid emails (with UUID suffix for uniqueness in parallel tests)
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

// Strategy for generating notes
fn notes_strategy() -> impl Strategy<Value = Option<String>> {
    prop::option::of("[a-zA-Z0-9 ]{10,100}".prop_map(|s| s.to_string()))
}

// Feature: bird-watching-platform, Property 6: Observation creation with user association
// **Validates: Requirements 2.1, 2.2**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_observation_creation_with_user_association(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy(),
        notes in notes_strategy()
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

            // Create an observation
            let observation_date = Utc::now() - Duration::days(1); // Yesterday
            let create_req = CreateObservationRequest {
                species_name: species.clone(),
                observation_date,
                location: location.clone(),
                latitude: None,
                longitude: None,
                notes: notes.clone(),
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let observation = observation_service.create(user_id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Verify observation is associated with user
            prop_assert_eq!(observation.user_id, user_id, "Observation should be associated with the user");
            prop_assert_eq!(observation.species_name, species, "Species name should match");
            prop_assert_eq!(observation.location, location, "Location should match");
            prop_assert_eq!(observation.notes, notes, "Notes should match");
            prop_assert!(observation.id.to_string().len() > 0, "Observation should have a valid UUID");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 7: User observation isolation
// **Validates: Requirements 2.3**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_user_observation_isolation(
        username1 in username_strategy(),
        username2 in username_strategy(),
        email1 in email_strategy(),
        email2 in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy()
    ) {
        // Ensure usernames and emails are different
        prop_assume!(username1 != username2);
        prop_assume!(email1 != email2);

        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username1).await;
            cleanup_user(&pool, &username2).await;

            // Register two users
            let user1 = auth_service.register(RegisterRequest {
                username: username1.clone(),
                email: email1.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("User1 registration failed: {}", e)))?;

            let user2 = auth_service.register(RegisterRequest {
                username: username2.clone(),
                email: email2.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("User2 registration failed: {}", e)))?;

            // Create observation for user1
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

            let obs1 = observation_service.create(user1.id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Get observations for user2
            let user2_observations = observation_service.get_user_observations(user2.id).await
                .map_err(|e| to_test_error(format!("Failed to get user2 observations: {}", e)))?;

            // User2 should not see user1's observation
            prop_assert!(!user2_observations.iter().any(|o| o.id == obs1.id),
                        "User2 should not see User1's observations");

            // Get observations for user1
            let user1_observations = observation_service.get_user_observations(user1.id).await
                .map_err(|e| to_test_error(format!("Failed to get user1 observations: {}", e)))?;

            // User1 should see their own observation
            prop_assert!(user1_observations.iter().any(|o| o.id == obs1.id),
                        "User1 should see their own observations");

            // Clean up
            cleanup_user(&pool, &username1).await;
            cleanup_user(&pool, &username2).await;

            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 8: Observation update persistence
// **Validates: Requirements 2.4**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_observation_update_persistence(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        species1 in species_strategy(),
        species2 in species_strategy(),
        location1 in location_strategy(),
        location2 in location_strategy()
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
            let create_req = CreateObservationRequest {
                species_name: species1.clone(),
                observation_date,
                location: location1.clone(),
                latitude: None,
                longitude: None,
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: false,
            };

            let observation = observation_service.create(user.id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Update the observation
            let update_req = bird_watching_backend::models::observation::UpdateObservationRequest {
                species_name: Some(species2.clone()),
                observation_date: None,
                location: Some(location2.clone()),
                latitude: None,
                longitude: None,
                notes: Some("Updated notes".to_string()),
                photo_url: None,
                trip_id: None,
                is_shared: Some(true),
            };

            let updated = observation_service.update(observation.id, user.id, update_req).await
                .map_err(|e| to_test_error(format!("Observation update failed: {}", e)))?;

            // Verify updates persisted
            prop_assert_eq!(updated.species_name, species2.clone(), "Species name should be updated");
            prop_assert_eq!(updated.location, location2.clone(), "Location should be updated");
            prop_assert_eq!(updated.notes, Some("Updated notes".to_string()), "Notes should be updated");
            prop_assert_eq!(updated.is_shared, true, "is_shared should be updated");

            // Retrieve the observation again to verify persistence
            let retrieved = observation_service.get_by_id(observation.id).await
                .map_err(|e| to_test_error(format!("Failed to retrieve observation: {}", e)))?;

            prop_assert_eq!(retrieved.species_name, species2, "Retrieved species name should match update");
            prop_assert_eq!(retrieved.location, location2, "Retrieved location should match update");

            // Clean up
            cleanup_user(&pool, &username).await;

            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 9: Unauthorized update rejection
// **Validates: Requirements 2.5**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]

    #[test]
    fn test_property_unauthorized_update_rejection(
        username1 in username_strategy(),
        username2 in username_strategy(),
        email1 in email_strategy(),
        email2 in email_strategy(),
        password in password_strategy(),
        species in species_strategy(),
        location in location_strategy()
    ) {
        // Ensure usernames and emails are different
        prop_assume!(username1 != username2);
        prop_assume!(email1 != email2);

        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            let observation_service = ObservationService::new(pool.clone());

            // Clean up any existing test data
            cleanup_user(&pool, &username1).await;
            cleanup_user(&pool, &username2).await;

            // Register two users
            let user1 = auth_service.register(RegisterRequest {
                username: username1.clone(),
                email: email1.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("User1 registration failed: {}", e)))?;

            let user2 = auth_service.register(RegisterRequest {
                username: username2.clone(),
                email: email2.clone(),
                password: password.clone(),
            }).await.map_err(|e| to_test_error(format!("User2 registration failed: {}", e)))?;

            // Create observation for user1
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

            let observation = observation_service.create(user1.id, create_req).await
                .map_err(|e| to_test_error(format!("Observation creation failed: {}", e)))?;

            // Try to update observation as user2
            let update_req = bird_watching_backend::models::observation::UpdateObservationRequest {
                species_name: Some("Unauthorized Update".to_string()),
                observation_date: None,
                location: None,
                latitude: None,
                longitude: None,
                notes: None,
                photo_url: None,
                trip_id: None,
                is_shared: None,
            };

            let update_result = observation_service.update(observation.id, user2.id, update_req).await;

            // Update should fail
            prop_assert!(update_result.is_err(), "Update by non-owner should fail");
            prop_assert!(update_result.unwrap_err().contains("Unauthorized"),
                        "Error should indicate unauthorized access");

            // Verify observation was not modified
            let unchanged = observation_service.get_by_id(observation.id).await
                .map_err(|e| to_test_error(format!("Failed to retrieve observation: {}", e)))?;

            prop_assert_eq!(unchanged.species_name, species, "Species name should not be changed");

            // Clean up
            cleanup_user(&pool, &username1).await;
            cleanup_user(&pool, &username2).await;

            Ok(())
        });
        result?;
    }
}
