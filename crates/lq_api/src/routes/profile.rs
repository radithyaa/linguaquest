//! Profil pengguna, statistik, dan pencapaian.

use axum::extract::State;
use axum::Json;
use chrono::Utc;
use lq_types::{ProfileDto, UpdateProfileRequest, UserStats};

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub async fn profile(State(state): State<AppState>, user: AuthUser) -> ApiResult<ProfileDto> {
    let now = Utc::now();
    let profile = state.storage.write(|s| {
        let user_row = s.users.get(&user.user_id).cloned()?;
        // Regenerasi heart sebelum menampilkan statistik.
        if let Some(stats) = s.stats.get_mut(&user.user_id) {
            lq_db::users::regenerate_hearts_if_needed(stats, now);
        }
        Some(lq_db::users::profile(s, &user_row, now))
    });

    profile
        .map(Json)
        .ok_or_else(|| ApiError::not_found("Pengguna tidak ditemukan."))
}

pub async fn stats(State(state): State<AppState>, user: AuthUser) -> ApiResult<UserStats> {
    let now = Utc::now();
    let stats = state.storage.write(|s| {
        let profile = {
            let user_row = s.users.get(&user.user_id)?.clone();
            lq_db::users::profile(s, &user_row, now)
        };
        Some(profile.stats)
    });
    stats
        .map(Json)
        .ok_or_else(|| ApiError::not_found("Pengguna tidak ditemukan."))
}

pub async fn update_profile(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<UpdateProfileRequest>,
) -> ApiResult<ProfileDto> {
    if let Some(goal) = payload.daily_goal_xp {
        if !(10..=200).contains(&goal) {
            return Err(ApiError::bad_request("Target harian harus antara 10 dan 200 XP."));
        }
    }

    let now = Utc::now();
    let profile = state.storage.write(|s| {
        if let Some(name) = payload.display_name.as_ref() {
            if name.trim().is_empty() {
                return None;
            }
            if let Some(u) = s.users.get_mut(&user.user_id) {
                u.display_name = name.trim().to_string();
            }
        }
        if let Some(goal) = payload.daily_goal_xp {
            if let Some(stats) = s.stats.get_mut(&user.user_id) {
                stats.daily_goal_xp = goal;
            }
        }
        let user_row = s.users.get(&user.user_id)?.clone();
        Some(lq_db::users::profile(s, &user_row, now))
    });

    let profile = profile.ok_or_else(|| ApiError::not_found("Pengguna tidak ditemukan."))?;
    state.commit(Some(user.user_id)).await?;
    Ok(Json(profile))
}
