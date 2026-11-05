//! Health check & status sistem.

use axum::extract::State;
use axum::Json;
use chrono::Utc;
use lq_types::HealthDto;

use crate::state::AppState;

pub async fn health(State(state): State<AppState>) -> Json<HealthDto> {
    let redis = match (&state.redis, state.redis_status()) {
        (Some(handle), _) => match handle.try_lock() {
            Ok(mut conn) => match redis::cmd("PING").query_async::<String>(&mut *conn).await {
                Ok(_) => "connected",
                Err(_) => "unreachable",
            },
            Err(_) => "connected",
        },
        (None, status) => status,
    };

    Json(HealthDto {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        database: state.database_status().to_string(),
        redis: redis.to_string(),
        uptime_seconds: (Utc::now() - state.started_at).num_seconds(),
        server_time: Utc::now(),
    })
}
