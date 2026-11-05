//! Quest harian & lencana bulanan.

use axum::extract::{Path, State};
use axum::Json;
use chrono::Utc;
use lq_types::{ClaimQuestResponse, QuestOverviewDto};

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub async fn overview(State(state): State<AppState>, user: AuthUser) -> ApiResult<QuestOverviewDto> {
    let overview = state.storage.read(|s| lq_db::quests::overview(s, user.user_id));
    Ok(Json(overview))
}

pub async fn claim(
    State(state): State<AppState>,
    user: AuthUser,
    Path(code): Path<String>,
) -> ApiResult<ClaimQuestResponse> {
    let result: Result<ClaimQuestResponse, ApiError> = state.storage.write(|s| {
        let gems = lq_db::quests::claim(s, user.user_id, &code).map_err(|error| match error {
            lq_db::quests::ClaimError::NotFound => ApiError::not_found("Quest tidak ditemukan."),
            lq_db::quests::ClaimError::NotCompleted => ApiError::conflict_named(
                "QUEST_INCOMPLETE",
                "Quest Belum Selesai",
                "Selesaikan target quest terlebih dahulu.",
            ),
            lq_db::quests::ClaimError::AlreadyClaimed => ApiError::conflict_named(
                "QUEST_CLAIMED",
                "Quest Sudah Diklaim",
                "Reward quest hari ini sudah diambil.",
            ),
        })?;
        let stats = s
            .stats
            .get(&user.user_id)
            .cloned()
            .ok_or_else(|| ApiError::not_found("Pengguna tidak ditemukan."))?;
        Ok(ClaimQuestResponse {
            gems_awarded: gems,
            stats: lq_db::users::to_stats_dto(s, &stats, Utc::now()),
        })
    });

    let response = result?;
    state.commit(Some(user.user_id)).await?;
    Ok(Json(response))
}
