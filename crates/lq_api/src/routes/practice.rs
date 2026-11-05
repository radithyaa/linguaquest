//! Latihan FSRS 4.5: ringkasan kartu & ulasan.

use axum::extract::State;
use axum::Json;
use chrono::Utc;
use lq_types::{FsrsReviewRequest, FsrsReviewResponse, PracticeOverviewDto};

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub async fn overview(State(state): State<AppState>, user: AuthUser) -> ApiResult<PracticeOverviewDto> {
    let now = Utc::now();
    let overview = state
        .storage
        .read(|s| lq_db::srs::overview(s, user.user_id, now));
    Ok(Json(overview))
}

pub async fn review(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<FsrsReviewRequest>,
) -> ApiResult<FsrsReviewResponse> {
    if lq_types::FsrsRating::from_i32(payload.rating).is_none() {
        return Err(ApiError::bad_request("Rating FSRS harus bernilai 1..4."));
    }
    let now = payload.reviewed_at.unwrap_or_else(Utc::now);

    let card = state.storage.write(|s| {
        let card = lq_db::srs::review(s, user.user_id, payload.card_id, payload.rating, now)?;
        if let Some(op) = payload.client_op_id {
            s.applied_ops.insert(op);
        }
        // Ulasan kartu menandai mistake terkait telah ditinjau.
        let word = card.word.to_lowercase();
        for ((uid, _), mistake) in s.mistakes.iter_mut() {
            if *uid == user.user_id && mistake.prompt.to_lowercase() == word {
                mistake.reviewed_at = Some(now);
            }
        }
        Some(lq_db::srs::to_dto(&card, now))
    });

    let card = card.ok_or_else(|| ApiError::not_found("Kartu FSRS tidak ditemukan."))?;
    state.commit(Some(user.user_id)).await?;
    Ok(Json(FsrsReviewResponse { card }))
}
