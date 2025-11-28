use crate::models::user::{LoginRequest, LoginResponse, RegisterRequest, User, UserProfile};
use crate::repositories::user_repository::UserRepository;
use crate::utils::jwt::generate_token;
use crate::utils::password::{hash_password, verify_password};
use sqlx::PgPool;

pub struct AuthService {
    user_repo: UserRepository,
}

impl AuthService {
    pub fn new(pool: PgPool) -> Self {
        Self {
            user_repo: UserRepository::new(pool),
        }
    }

    /// Register a new user
    pub async fn register(&self, req: RegisterRequest) -> Result<UserProfile, String> {
        // Check if username already exists
        if self.user_repo.username_exists(&req.username).await.map_err(|e| e.to_string())? {
            return Err("Username already exists".to_string());
        }

        // Check if email already exists
        if self.user_repo.email_exists(&req.email).await.map_err(|e| e.to_string())? {
            return Err("Email already exists".to_string());
        }

        // Hash the password
        let password_hash = hash_password(&req.password).map_err(|e| e.to_string())?;

        // Create the user
        let user = self
            .user_repo
            .create(&req.username, &req.email, &password_hash)
            .await
            .map_err(|e| e.to_string())?;

        Ok(user.into())
    }

    /// Authenticate a user and return a token
    pub async fn login(&self, req: LoginRequest) -> Result<LoginResponse, String> {
        // Find user by username
        let user = self
            .user_repo
            .find_by_username(&req.username)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "Invalid credentials".to_string())?;

        // Verify password
        let is_valid = verify_password(&req.password, &user.password_hash)
            .map_err(|e| e.to_string())?;

        if !is_valid {
            return Err("Invalid credentials".to_string());
        }

        // Generate JWT token
        let token = generate_token(user.id, &user.username).map_err(|e| e.to_string())?;

        Ok(LoginResponse {
            token,
            user: user.into(),
        })
    }

    /// Get user profile by ID
    pub async fn get_user_profile(&self, user_id: uuid::Uuid) -> Result<UserProfile, String> {
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "User not found".to_string())?;

        Ok(user.into())
    }
}

