//! Autentikasi: registrasi, login, tamu, refresh, upgrade, logout.

use axum::extract::State;
use axum::Json;
use chrono::Utc;
use lq_types::{
    AuthResponse, GuestRequest, LoginRequest, RefreshRequest, RefreshResponse, RegisterRequest,
    UpgradeGuestRequest,
};
use uuid::Uuid;

use crate::auth::{
    self, hash_password, hash_refresh_token, new_refresh_token, verify_access_token, verify_password,
    REFRESH_TOKEN_TTL_SECONDS,
};
use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub const DEMO_USER_ID: &str = "00000000-0000-4000-8000-000000000901";

/// Daftarkan akun baru (AUTH-01).
pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> ApiResult<AuthResponse> {
    let email = payload.email.trim().to_lowercase();
    if !email.contains('@') || !email.contains('.') {
        return Err(ApiError::bad_request("Format email tidak valid."));
    }
    let password_hash = hash_password(&payload.password)?;
    let display_name = payload.display_name.trim().to_string();
    if display_name.is_empty() {
        return Err(ApiError::bad_request("Nama tampilan wajib diisi."));
    }

    let exists = state.storage.read(|s| s.find_user_by_email(&email).is_some());
    if exists {
        return Err(ApiError::conflict("EMAIL_TAKEN", "Email sudah terdaftar."));
    }
    if let Some(username) = payload.username.as_deref() {
        let taken = state.storage.read(|s| s.find_user_by_username(username).is_some());
        if taken {
            return Err(ApiError::conflict("USERNAME_TAKEN", "Username sudah dipakai."));
        }
    }

    let (user_dto, refresh) = state.storage.write(|s| {
        let user = lq_db::users::new_user(
            s,
            &email,
            &display_name,
            payload.username.as_deref(),
            Some(password_hash),
            false,
        );
        (lq_db::users::to_user_dto(&user), new_refresh_token())
    });

    state.commit(Some(user_dto.id)).await?;
    let mut response = auth::auth_response(&state.jwt_secret, user_dto)?;
    response.refresh_token = refresh;
    Ok(Json(response))
}

/// Login email + password.
pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> ApiResult<AuthResponse> {
    let email = payload.email.trim().to_lowercase();
    let user = state.storage.read(|s| s.find_user_by_email(&email).cloned());

    let Some(user) = user else {
        return Err(ApiError::unauthorized("Email atau kata sandi salah."));
    };

    let is_demo = user.id.to_string() == DEMO_USER_ID;
    let allowed = match &user.password_hash {
        Some(hash) => verify_password(&payload.password, hash),
        None => is_demo && payload.password == DEMO_PASSWORD,
    };
    if !allowed {
        return Err(ApiError::unauthorized("Email atau kata sandi salah."));
    }

    let user_dto = lq_db::users::to_user_dto(&user);
    let mut response = auth::auth_response(&state.jwt_secret, user_dto)?;
    let token = response.refresh_token.clone();
    store_refresh(&state, user.id, &token);
    state.commit(Some(user.id)).await?;
    response.refresh_token = token;
    Ok(Json(response))
}

/// Kata sandi akun demo bawaan (dibuat saat startup oleh `lq_db`).
pub const DEMO_PASSWORD: &str = "demo12345";

/// Mode tamu (AUTH-04).
pub async fn guest(
    State(state): State<AppState>,
    Json(payload): Json<GuestRequest>,
) -> ApiResult<AuthResponse> {
    let display_name = payload
        .display_name
        .unwrap_or_else(|| "Pelajar Tamu".to_string());

    let (user_dto, token) = state.storage.write(|s| {
        let email = format!("tamu-{}@guest.linguaquest.app", &Uuid::new_v4().simple().to_string()[..10]);
        let user = lq_db::users::new_user(s, &email, &display_name, None, None, true);
        (lq_db::users::to_user_dto(&user), new_refresh_token())
    });

    store_refresh(&state, user_dto.id, &token);
    state.commit(Some(user_dto.id)).await?;
    let mut response = auth::auth_response(&state.jwt_secret, user_dto)?;
    response.refresh_token = token;
    Ok(Json(response))
}

/// Rotasi refresh token (mencegah replay).
pub async fn refresh(
    State(state): State<AppState>,
    Json(payload): Json<RefreshRequest>,
) -> ApiResult<RefreshResponse> {
    let token_hash = hash_refresh_token(&payload.refresh_token);
    let token_key = state
        .storage
        .read(|s| s.refresh_tokens.get(&token_hash).cloned())
        .ok_or_else(|| ApiError::unauthorized("Refresh token tidak dikenal."))?;

    if token_key.expires_at < Utc::now() || token_key.revoked {
        return Err(ApiError::unauthorized("Refresh token sudah kedaluwarsa."));
    }

    let new_token = new_refresh_token();
    let user_id = token_key.user_id;
    state.storage.write(|s| {
        if let Some(existing) = s.refresh_tokens.get_mut(&token_hash) {
            existing.revoked = true;
        }
        s.refresh_tokens.insert(
            hash_refresh_token(&new_token),
            lq_db::db::RefreshTokenRow {
                user_id,
                expires_at: Utc::now() + chrono::Duration::seconds(REFRESH_TOKEN_TTL_SECONDS),
                revoked: false,
            },
        );
    });
    state.commit(Some(user_id)).await?;

    Ok(Json(RefreshResponse {
        access_token: auth::issue_access_token(&state.jwt_secret, user_id)?,
        refresh_token: new_token,
        expires_in: auth::ACCESS_TOKEN_TTL_SECONDS,
    }))
}

/// Migrasi akun tamu menjadi akun permanen.
pub async fn upgrade(
    State(state): State<AppState>,
    auth_user: AuthUser,
    Json(payload): Json<UpgradeGuestRequest>,
) -> ApiResult<AuthResponse> {
    let email = payload.email.trim().to_lowercase();
    if !email.contains('@') {
        return Err(ApiError::bad_request("Format email tidak valid."));
    }
    let password_hash = hash_password(&payload.password)?;

    let user = state.storage.read(|s| s.users.get(&auth_user.user_id).cloned());
    let Some(user) = user else {
        return Err(ApiError::not_found("Pengguna tidak ditemukan."));
    };
    if !user.is_guest {
        return Err(ApiError::conflict("ALREADY_REGISTERED", "Akun ini sudah terdaftar."));
    }
    let email_taken = state.storage.read(|s| s.find_user_by_email(&email).is_some());
    if email_taken {
        return Err(ApiError::conflict("EMAIL_TAKEN", "Email sudah terdaftar."));
    }

    let user_dto = state.storage.write(|s| {
        let entry = s.users.get_mut(&auth_user.user_id)?;
        entry.email = email;
        entry.password_hash = Some(password_hash);
        entry.is_guest = false;
        entry.display_name = payload.display_name;
        if let Some(username) = payload.username {
            entry.username = username;
        }
        Some(lq_db::users::to_user_dto(entry))
    });
    let user_dto = user_dto.ok_or_else(|| ApiError::not_found("Pengguna tidak ditemukan."))?;

    let token = new_refresh_token();
    store_refresh(&state, user_dto.id, &token);
    state.commit(Some(user_dto.id)).await?;
    let mut response = auth::auth_response(&state.jwt_secret, user_dto)?;
    response.refresh_token = token;
    Ok(Json(response))
}

/// Revoke refresh token perangkat ini.
pub async fn logout(
    State(state): State<AppState>,
    Json(payload): Json<RefreshRequest>,
) -> ApiResult<serde_json::Value> {
    let token_hash = hash_refresh_token(&payload.refresh_token);
    state.storage.write(|s| {
        if let Some(existing) = s.refresh_tokens.get_mut(&token_hash) {
            existing.revoked = true;
        }
    });
    state.commit(None).await?;
    Ok(Json(serde_json::json!({ "success": true })))
}

/// Simpan hash refresh token ke penyimpanan.
fn store_refresh(state: &AppState, user_id: Uuid, token: &str) {
    let hash = hash_refresh_token(token);
    state.storage.write(|s| {
        s.refresh_tokens.insert(
            hash,
            lq_db::db::RefreshTokenRow {
                user_id,
                expires_at: Utc::now() + chrono::Duration::seconds(REFRESH_TOKEN_TTL_SECONDS),
                revoked: false,
            },
        );
    });
}

/// Validasi token untuk test integrasi.
pub fn decode_for_test(secret: &str, token: &str) -> Option<Uuid> {
    verify_access_token(secret, token).ok().map(|c| c.sub)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn demo_password_constant_is_documented() {
        assert_eq!(DEMO_PASSWORD, "demo12345");
    }
}
