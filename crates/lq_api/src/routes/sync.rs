//! Sinkronisasi offline-first (SRS Bab 11): sesi yang direkam di Drift dikirim
//! sekaligus saat koneksi tersedia.

use axum::extract::State;
use axum::Json;
use chrono::Utc;
use lq_types::{OfflineSessionPayload, RejectedOp, SessionSummaryDto, SyncRequest, SyncResponse};

use crate::error::{ApiResult, AuthUser};
use crate::AppState;

/// Samakan state server: XP bersifat aditif, progres node memakai status
/// tertinggi, dan operasi yang sudah pernah diterapkan diabaikan (idempotent).
pub async fn sync(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<SyncRequest>,
) -> ApiResult<SyncResponse> {
    let mut applied = Vec::new();
    let mut rejected = Vec::new();
    let mut summaries: Vec<SessionSummaryDto> = Vec::new();

    for session in payload.sessions {
        let outcome = apply_session(&state, user.user_id, &session);
        match outcome {
            Ok(summary) => {
                applied.push(session.client_op_id);
                if let Some(summary) = summary {
                    summaries.push(summary);
                }
            }
            Err(reason) => rejected.push(RejectedOp {
                client_op_id: session.client_op_id,
                reason,
            }),
        }
    }

    for review in payload.reviews {
        let card_exists = state
            .storage
            .read(|s| s.cards.values().any(|c| c.user_id == user.user_id && c.id == review.card_id));
        if !card_exists {
            if let Some(op) = review.client_op_id {
                rejected.push(RejectedOp { client_op_id: op, reason: "kartu_fsrs_tidak_ditemukan".into() });
            }
            continue;
        }
        let reviewed_at = review.reviewed_at.unwrap_or_else(Utc::now);
        state.storage.write(|s| {
            lq_db::srs::review(s, user.user_id, review.card_id, review.rating, reviewed_at);
            if let Some(op) = review.client_op_id {
                s.applied_ops.insert(op);
                applied.push(op);
            }
        });
    }

    for purchase in payload.purchases {
        let result = state.storage.write(|s| {
            lq_db::gamification::purchase(s, user.user_id, &purchase.sku, purchase.client_op_id)
        });
        match result {
            Ok(_) => {
                if let Some(op) = purchase.client_op_id {
                    applied.push(op);
                }
            }
            Err(error) => {
                if let Some(op) = purchase.client_op_id {
                    rejected.push(RejectedOp { client_op_id: op, reason: error.code().to_string() });
                }
            }
        }
    }

    let stats = state.storage.write(|s| {
        let stats = s.stats.get(&user.user_id).cloned()?;
        Some(lq_db::users::to_stats_dto(s, &stats, Utc::now()))
    });

    state.commit(Some(user.user_id)).await?;
    let stats = stats.ok_or_else(|| crate::error::ApiError::not_found("Pengguna tidak ditemukan."))?;

    Ok(Json(SyncResponse {
        applied_ops: applied,
        rejected_ops: rejected,
        summaries,
        stats,
    }))
}

fn apply_session(
    state: &AppState,
    user_id: uuid::Uuid,
    session: &OfflineSessionPayload,
) -> Result<Option<SessionSummaryDto>, String> {
    let already = state.storage.read(|s| s.applied_ops.contains(&session.client_op_id));
    if already {
        // Operasi duplikat: anggap sukses tanpa menerapkan ulang.
        return Ok(None);
    }

    state
        .storage
        .write(|s| {
            let lesson_id = s
                .lesson_of_node(session.node_id)
                .map(|l| l.id)
                .ok_or_else(|| "node_tidak_ditemukan".to_string())?;
            let summary = lq_db::learning::commit_session(
                s,
                user_id,
                session.node_id,
                lesson_id,
                session.started_at,
                session.completed_at,
                session.duration_ms,
                session.client_op_id,
                &session.answers,
            );
            summary.ok_or_else(|| "sesi_gagal_diproses".to_string())
        })
        .map(Some)
}
