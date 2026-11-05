//! Autentikasi: Argon2id, JWT akses, dan refresh token berotasi (SRS AUTH-01).

use std::time::{SystemTime, UNIX_EPOCH};

use argon2::password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString};
use argon2::Argon2;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use lq_types::AuthResponse;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::error::ApiError;

pub const ACCESS_TOKEN_TTL_SECONDS: i64 = 60 * 60 * 24; // 24 jam (MVP)
pub const REFRESH_TOKEN_TTL_SECONDS: i64 = 60 * 60 * 24 * 30; // 30 hari

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub exp: i64,
    pub iat: i64,
    pub jti: Uuid,
}

pub fn hash_password(password: &str) -> Result<String, ApiError> {
    if password.len() < 8 {
        return Err(ApiError::bad_request("Kata sandi minimal 8 karakter."));
    }
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|_| ApiError::internal("Gagal memproses kata sandi."))
}

pub fn verify_password(password: &str, hash: &str) -> bool {
    let Ok(parsed) = PasswordHash::new(hash) else {
        return false;
    };
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed)
        .is_ok()
}

pub fn issue_access_token(secret: &str, user_id: Uuid) -> Result<String, ApiError> {
    let now = unix_now();
    let claims = Claims {
        sub: user_id,
        iat: now,
        exp: now + ACCESS_TOKEN_TTL_SECONDS,
        jti: Uuid::new_v4(),
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|_| ApiError::internal("Gagal membuat access token."))
}

pub fn verify_access_token(secret: &str, token: &str) -> Result<Claims, ApiError> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|_| ApiError::unauthorized("Token tidak valid atau sudah kedaluwarsa."))
}

/// Refresh token disimpan sebagai SHA-256 (tidak pernah plaintext).
pub fn hash_refresh_token(token: &str) -> String {
    hex::encode(Sha256::digest(token.as_bytes()))
}

pub fn new_refresh_token() -> String {
    use rand::RngCore;
    let mut bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut bytes);
    hex::encode(bytes)
}

pub fn auth_response(secret: &str, user: lq_types::UserDto) -> Result<AuthResponse, ApiError> {
    Ok(AuthResponse {
        access_token: issue_access_token(secret, user.id)?,
        refresh_token: new_refresh_token(),
        expires_in: ACCESS_TOKEN_TTL_SECONDS,
        user,
    })
}

pub fn unix_now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn password_hash_roundtrip() {
        let hash = hash_password("rahasia123").unwrap();
        assert!(verify_password("rahasia123", &hash));
        assert!(!verify_password("salah", &hash));
    }

    #[test]
    fn short_password_rejected() {
        assert!(hash_password("123").is_err());
    }

    #[test]
    fn jwt_roundtrip() {
        let user_id = Uuid::new_v4();
        let token = issue_access_token("secret-test", user_id).unwrap();
        let claims = verify_access_token("secret-test", &token).unwrap();
        assert_eq!(claims.sub, user_id);
        assert!(verify_access_token("secret-lain", &token).is_err());
    }
}
