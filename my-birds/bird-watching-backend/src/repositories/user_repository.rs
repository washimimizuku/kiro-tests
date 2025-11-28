use crate::models::user::User;
use sqlx::{PgPool, Result};
use uuid::Uuid;

/// Repository for user database operations
pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Create a new user in the database
    pub async fn create(&self, username: &str, email: &str, password_hash: &str) -> Result<User> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (username, email, password_hash)
            VALUES ($1, $2, $3)
            RETURNING id, username, email, password_hash, created_at
            "#,
        )
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    /// Find a user by username
    pub async fn find_by_username(&self, username: &str) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT id, username, email, password_hash, created_at
            FROM users
            WHERE username = $1
            "#,
        )
        .bind(username)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Find a user by email
    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT id, username, email, password_hash, created_at
            FROM users
            WHERE email = $1
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Find a user by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT id, username, email, password_hash, created_at
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Check if a username already exists
    pub async fn username_exists(&self, username: &str) -> Result<bool> {
        let exists: (bool,) = sqlx::query_as(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)
            "#,
        )
        .bind(username)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists.0)
    }

    /// Check if an email already exists
    pub async fn email_exists(&self, email: &str) -> Result<bool> {
        let exists: (bool,) = sqlx::query_as(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)
            "#,
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists.0)
    }
}
