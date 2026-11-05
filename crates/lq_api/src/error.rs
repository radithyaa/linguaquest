//! Utilitas HTTP: error RFC 9457, ekstraktor autentikasi, dan helper state.

use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::Json;
use lq_types::ProblemDetails;
use uuid::Uuid;

use crate::AppState;

/// Error API yang dipetakan ke Problem Details (SRS 7.3).
#[derive(Debug, Clone)]
pub struct ApiError {
    pub status: StatusCode,
    pub code: &'static str,
    pub title: &'static str,
    pub detail: String,
}

impl ApiError {
    pub fn new(status: StatusCode, code: &'static str, title: &'static str, detail: impl Into<String>) -> Self {
        Self { status, code, title, detail: detail.into() }
    }

    pub fn bad_request(detail: impl Into<String>) -> Self {
        Self::new(StatusCode::BAD_REQUEST, "VALIDATION_ERROR", "Permintaan Tidak Valid", detail)
    }

    pub fn unauthorized(detail: impl Into<String>) -> Self {
        Self::new(StatusCode::UNAUTHORIZED, "UNAUTHORIZED", "Tidak Terautentikasi", detail)
    }

    pub fn forbidden(code: &'static str, title: &'static str, detail: impl Into<String>) -> Self {
        Self::new(StatusCode::FORBIDDEN, code, title, detail)
    }

    pub fn not_found(detail: impl Into<String>) -> Self {
        Self::new(StatusCode::NOT_FOUND, "NOT_FOUND", "Data Tidak Ditemukan", detail)
    }

    pub fn conflict(code: &'static str, detail: impl Into<String>) -> Self {
        Self::new(StatusCode::CONFLICT, code, "Konflik Data", detail)
    }

    pub fn conflict_named(
        code: &'static str,
        title: &'static str,
        detail: impl Into<String>,
    ) -> Self {
        Self::new(StatusCode::CONFLICT, code, title, detail)
    }

    pub fn internal(detail: impl Into<String>) -> Self {
        Self::new(StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Kesalahan Server", detail)
    }
}

impl std::fmt::Display for ApiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} ({})", self.detail, self.code)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let problem = ProblemDetails::new(self.status.as_u16(), self.code, self.title, self.detail);
        (self.status, Json(problem)).into_response()
    }
}

impl From<anyhow::Error> for ApiError {
    fn from(value: anyhow::Error) -> Self {
        tracing::error!(error = %value, "kesalahan internal");
        ApiError::internal("Terjadi kesalahan pada server.")
    }
}

/// Pengguna terautentikasi (hasil validasi JWT).
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub user_id: Uuid,
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let token = bearer_token(&parts.headers)
            .ok_or_else(|| ApiError::unauthorized("Header Authorization: Bearer <token> wajib dikirim."))?;
        let claims = crate::auth::verify_access_token(&state.jwt_secret, &token)?;
        Ok(AuthUser { user_id: claims.sub })
    }
}

pub fn bearer_token(headers: &HeaderMap) -> Option<String> {
    headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "))
        .map(|token| token.trim().to_string())
        .filter(|token| !token.is_empty())
}

pub type ApiResult<T> = Result<Json<T>, ApiError>;

pub fn ok<T>(value: T) -> ApiResult<T> {
    Ok(Json(value))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn problem_details_shape() {
        let error = ApiError::forbidden("HEARTS_EXHAUSTED", "Hearts Depleted", "kosong");
        let problem = ProblemDetails::new(
            error.status.as_u16(),
            error.code,
            error.title,
            error.detail.clone(),
        );
        assert_eq!(problem.code, "HEARTS_EXHAUSTED");
        assert_eq!(problem.status, 403);
    }

    #[test]
    fn bearer_token_extraction() {
        let mut headers = HeaderMap::new();
        headers.insert("authorization", "Bearer abc.def.ghi".parse().unwrap());
        assert_eq!(bearer_token(&headers).as_deref(), Some("abc.def.ghi"));
    }
}
