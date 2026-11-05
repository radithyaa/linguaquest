//! Papan peringkat liga mingguan.

use axum::extract::State;
use axum::Json;
use lq_types::LeagueOverviewDto;

use crate::error::{ApiResult, AuthUser};
use crate::AppState;

pub async fn overview(State(state): State<AppState>, user: AuthUser) -> ApiResult<LeagueOverviewDto> {
    let overview = state
        .storage
        .read(|s| lq_db::league::overview(s, user.user_id));
    Ok(Json(overview))
}
