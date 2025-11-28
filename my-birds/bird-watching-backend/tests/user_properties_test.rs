use bird_watching_backend::models::user::RegisterRequest;
use bird_watching_backend::services::auth_service::AuthService;
use proptest::prelude::*;
use sqlx::postgres::PgPoolOptions;
use std::env;

// Helper function to get test database pool
async fn get_test_pool() -> sqlx::PgPool {
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:password@localhost:5432/bird_watching".to_string());
    
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

// Feature: bird-watching-platform, Property 1: Valid registration creates unique user
// **Validates: Requirements 1.1**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]
    
    #[test]
    fn test_property_valid_registration_creates_unique_user(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            
            // Clean up any existing test data
            cleanup_user(&pool, &username).await;
            
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };
            
            // Register the user
            let result = auth_service.register(register_req).await;
            
            // Clean up
            cleanup_user(&pool, &username).await;
            
            // Assert registration was successful
            prop_assert!(result.is_ok(), "Registration should succeed for valid data");
            
            let user_profile = result.unwrap();
            prop_assert_eq!(user_profile.username, username, "Username should match");
            prop_assert_eq!(user_profile.email, email, "Email should match");
            prop_assert!(user_profile.id.to_string().len() > 0, "User should have a valid UUID");
            
            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 2: Duplicate registration rejection
// **Validates: Requirements 1.2**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]
    
    #[test]
    fn test_property_duplicate_registration_rejection(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            
            // Clean up any existing test data
            cleanup_user(&pool, &username).await;
            
            let register_req1 = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };
            
            // Register the user first time
            let result1 = auth_service.register(register_req1).await;
            prop_assert!(result1.is_ok(), "First registration should succeed");
            
            // Try to register with same username
            let register_req2 = RegisterRequest {
                username: username.clone(),
                email: format!("different_{}", email),
                password: password.clone(),
            };
            
            let result2 = auth_service.register(register_req2).await;
            prop_assert!(result2.is_err(), "Duplicate username registration should fail");
            prop_assert!(result2.unwrap_err().contains("Username already exists"), 
                        "Error should indicate username exists");
            
            // Try to register with same email
            let register_req3 = RegisterRequest {
                username: format!("different_{}", username),
                email: email.clone(),
                password: password.clone(),
            };
            
            let result3 = auth_service.register(register_req3).await;
            prop_assert!(result3.is_err(), "Duplicate email registration should fail");
            prop_assert!(result3.unwrap_err().contains("Email already exists"), 
                        "Error should indicate email exists");
            
            // Clean up
            cleanup_user(&pool, &username).await;
            
            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 3: Valid authentication returns token
// **Validates: Requirements 1.3**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]
    
    #[test]
    fn test_property_valid_authentication_returns_token(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            
            // Clean up any existing test data
            cleanup_user(&pool, &username).await;
            
            // Register a user
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };
            
            let reg_result = auth_service.register(register_req).await;
            prop_assert!(reg_result.is_ok(), "Registration should succeed");
            
            // Try to login with correct credentials
            let login_req = bird_watching_backend::models::user::LoginRequest {
                username: username.clone(),
                password: password.clone(),
            };
            
            let login_result = auth_service.login(login_req).await;
            
            // Clean up
            cleanup_user(&pool, &username).await;
            
            prop_assert!(login_result.is_ok(), "Login should succeed with valid credentials");
            
            let login_response = login_result.unwrap();
            prop_assert!(login_response.token.len() > 0, "Token should not be empty");
            prop_assert_eq!(login_response.user.username, username, "Username should match");
            
            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 4: Invalid credentials rejection
// **Validates: Requirements 1.4**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]
    
    #[test]
    fn test_property_invalid_credentials_rejection(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy(),
        wrong_password in password_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            
            // Clean up any existing test data
            cleanup_user(&pool, &username).await;
            
            // Register a user
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };
            
            let reg_result = auth_service.register(register_req).await;
            prop_assert!(reg_result.is_ok(), "Registration should succeed");
            
            // Try to login with wrong password
            let login_req = bird_watching_backend::models::user::LoginRequest {
                username: username.clone(),
                password: wrong_password.clone(),
            };
            
            let login_result = auth_service.login(login_req).await;
            
            // Only assert failure if the wrong password is actually different
            if wrong_password != password {
                prop_assert!(login_result.is_err(), "Login should fail with wrong password");
                prop_assert!(login_result.unwrap_err().contains("Invalid credentials"), 
                            "Error should indicate invalid credentials");
            }
            
            // Try to login with non-existent username
            let login_req2 = bird_watching_backend::models::user::LoginRequest {
                username: format!("nonexistent_{}", username),
                password: password.clone(),
            };
            
            let login_result2 = auth_service.login(login_req2).await;
            prop_assert!(login_result2.is_err(), "Login should fail with non-existent username");
            prop_assert!(login_result2.unwrap_err().contains("Invalid credentials"), 
                        "Error should indicate invalid credentials");
            
            // Clean up
            cleanup_user(&pool, &username).await;
            
            Ok(())
        });
        result?;
    }
}


// Feature: bird-watching-platform, Property 5: Profile excludes password
// **Validates: Requirements 1.5**
proptest! {
    #![proptest_config(ProptestConfig::with_cases(10))]
    
    #[test]
    fn test_property_profile_excludes_password(
        username in username_strategy(),
        email in email_strategy(),
        password in password_strategy()
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let result = rt.block_on(async {
            let pool = get_test_pool().await;
            let auth_service = AuthService::new(pool.clone());
            
            // Clean up any existing test data
            cleanup_user(&pool, &username).await;
            
            // Register a user
            let register_req = RegisterRequest {
                username: username.clone(),
                email: email.clone(),
                password: password.clone(),
            };
            
            let reg_result = auth_service.register(register_req).await;
            prop_assert!(reg_result.is_ok(), "Registration should succeed");
            
            let user_profile = reg_result.unwrap();
            let user_id = user_profile.id;
            
            // Get user profile
            let profile_result = auth_service.get_user_profile(user_id).await;
            prop_assert!(profile_result.is_ok(), "Getting profile should succeed");
            
            let profile = profile_result.unwrap();
            
            // Verify profile data
            prop_assert_eq!(profile.username.clone(), username.clone(), "Username should match");
            prop_assert_eq!(profile.email.clone(), email.clone(), "Email should match");
            prop_assert_eq!(profile.id, user_id, "User ID should match");
            
            // Serialize profile to JSON to verify password is not included
            let json = serde_json::to_string(&profile).unwrap();
            prop_assert!(!json.contains("password"), "Serialized profile should not contain password field");
            prop_assert!(!json.contains(&password), "Serialized profile should not contain password value");
            
            // Clean up
            cleanup_user(&pool, &username).await;
            
            Ok(())
        });
        result?;
    }
}
