use bcrypt::{hash, verify, DEFAULT_COST};

/// Hash a password using bcrypt
pub fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, DEFAULT_COST)
}

/// Verify a password against a hash
pub fn verify_password(password: &str, hash: &str) -> Result<bool, bcrypt::BcryptError> {
    verify(password, hash)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_and_verify_password() {
        let password = "test_password_123";
        let hash = hash_password(password).expect("Failed to hash password");
        
        assert!(verify_password(password, &hash).expect("Failed to verify password"));
        assert!(!verify_password("wrong_password", &hash).expect("Failed to verify password"));
    }

    #[test]
    fn test_different_passwords_produce_different_hashes() {
        let password1 = "password1";
        let password2 = "password2";
        
        let hash1 = hash_password(password1).expect("Failed to hash password1");
        let hash2 = hash_password(password2).expect("Failed to hash password2");
        
        assert_ne!(hash1, hash2);
    }

    #[test]
    fn test_same_password_produces_different_hashes() {
        let password = "same_password";
        
        let hash1 = hash_password(password).expect("Failed to hash password");
        let hash2 = hash_password(password).expect("Failed to hash password");
        
        // Bcrypt includes a salt, so same password should produce different hashes
        assert_ne!(hash1, hash2);
        
        // But both should verify correctly
        assert!(verify_password(password, &hash1).expect("Failed to verify"));
        assert!(verify_password(password, &hash2).expect("Failed to verify"));
    }
}
