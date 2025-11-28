use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::env;
use uuid::Uuid;

/// JWT Claims structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,  // Subject (user ID)
    pub username: String,
    pub exp: i64,     // Expiration time
    pub iat: i64,     // Issued at
}

/// Generate a JWT token for a user
pub fn generate_token(user_id: Uuid, username: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default-secret-key".to_string());
    
    let expiration = Utc::now()
        .checked_add_signed(Duration::hours(24))
        .expect("valid timestamp")
        .timestamp();
    
    let claims = Claims {
        sub: user_id.to_string(),
        username: username.to_string(),
        exp: expiration,
        iat: Utc::now().timestamp(),
    };
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

/// Validate a JWT token and extract claims
pub fn validate_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let secret = env::var("JWT_SECRET").unwrap_or_else(|_| "default-secret-key".to_string());
    
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;
    
    Ok(token_data.claims)
}

/// Extract user ID from JWT claims
pub fn extract_user_id(claims: &Claims) -> Result<Uuid, uuid::Error> {
    Uuid::parse_str(&claims.sub)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_validate_token() {
        let user_id = Uuid::new_v4();
        let username = "testuser";
        
        let token = generate_token(user_id, username).expect("Failed to generate token");
        let claims = validate_token(&token).expect("Failed to validate token");
        
        assert_eq!(claims.username, username);
        assert_eq!(claims.sub, user_id.to_string());
    }

    #[test]
    fn test_extract_user_id() {
        let user_id = Uuid::new_v4();
        let username = "testuser";
        
        let token = generate_token(user_id, username).expect("Failed to generate token");
        let claims = validate_token(&token).expect("Failed to validate token");
        let extracted_id = extract_user_id(&claims).expect("Failed to extract user ID");
        
        assert_eq!(extracted_id, user_id);
    }

    #[test]
    fn test_invalid_token() {
        let result = validate_token("invalid.token.here");
        assert!(result.is_err());
    }

    #[test]
    fn test_token_expiration_is_set() {
        let user_id = Uuid::new_v4();
        let username = "testuser";
        
        let token = generate_token(user_id, username).expect("Failed to generate token");
        let claims = validate_token(&token).expect("Failed to validate token");
        
        let now = Utc::now().timestamp();
        assert!(claims.exp > now, "Token should expire in the future");
        assert!(claims.iat <= now, "Token should be issued at or before now");
    }
}

