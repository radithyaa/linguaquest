//! Sesi pelajaran: start (nonce) dan complete (validasi + transaksi atomik).

use axum::extract::State;
use axum::Json;
use chrono::{Duration, Utc};
use lq_types::{
    CompleteSessionRequest, SessionSummaryDto, StartSessionRequest, StartSessionResponse,
};
use uuid::Uuid;

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::state::AppState;

const SESSION_TTL_MINUTES: i64 = 60;

/// `POST /v1/sessions/start` — terbitkan nonce sesi (SRS 7.4).
pub async fn start(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<StartSessionRequest>,
) -> ApiResult<StartSessionResponse> {
    let now = Utc::now();

    let prepared = state.storage.write(|s| {
        // Regenerasi heart berdasarkan waktu.
        if let Some(stats) = s.stats.get_mut(&user.user_id) {
            lq_db::users::regenerate_hearts_if_needed(stats, now);
        }
        let stats = s.stats.get(&user.user_id).cloned()?;
        let node = s.node(payload.node_id)?.clone();
        let unlocked = s.unlocked_position(user.user_id, node.id);
        if node.position > unlocked {
            return Some(Err(ApiError::forbidden(
                "NODE_LOCKED",
                "Node Terkunci",
                "Selesaikan node sebelumnya terlebih dahulu.",
            )));
        }
        if stats.hearts <= 0 {
            return Some(Err(ApiError::forbidden(
                "HEARTS_EXHAUSTED",
                "Hearts Depleted",
                "Anda tidak memiliki sisa Heart. Isi ulang di Toko atau tunggu regenerasi.",
            )));
        }
        let lesson = s.lesson_of_node(node.id)?.clone();
        let exercises = s.lesson_exercises(lesson.id);
        let exercise_ids: Vec<Uuid> = exercises.iter().map(|e| e.id).collect();
        let session_id = Uuid::new_v4();
        let expires_at = now + Duration::minutes(SESSION_TTL_MINUTES);
        s.sessions.insert(
            session_id,
            lq_db::db::SessionRow {
                id: session_id,
                user_id: user.user_id,
                node_id: node.id,
                lesson_id: lesson.id,
                started_at: now,
                expires_at,
                exercise_ids,
            },
        );
        Some(Ok(StartSessionResponse {
            session_id,
            lesson_id: lesson.id,
            node_id: node.id,
            exercises: exercises.iter().map(lq_db::curriculum::to_exercise_dto).collect(),
            hearts: stats.hearts,
            expires_at,
        }))
    });

    match prepared {
        Some(Ok(response)) => Ok(Json(response)),
        Some(Err(error)) => Err(error),
        None => Err(ApiError::not_found("Node pelajaran tidak ditemukan.")),
    }
}

/// `POST /v1/sessions/complete` — validasi jawaban, hitung XP, dan simpan atomik.
pub async fn complete(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<CompleteSessionRequest>,
) -> ApiResult<SessionSummaryDto> {
    let now = Utc::now();

    // Idempotensi: operasi yang sudah diterapkan mengembalikan ringkasan terakhir.
    let already = state
        .storage
        .read(|s| s.applied_ops.contains(&payload.client_op_id));
    if already {
        return Err(ApiError::conflict_named(
            "DUPLICATE_OP",
            "Operasi Sudah Diproses",
            "client_op_id ini sudah diterapkan pada sesi sebelumnya.",
        ));
    }

    if payload.answers.is_empty() {
        return Err(ApiError::bad_request("Daftar jawaban tidak boleh kosong."));
    }

    let session = payload
        .session_id
        .and_then(|id| state.storage.read(|s| s.sessions.get(&id).cloned()));
    if let Some(session) = &session {
        if session.user_id != user.user_id {
            return Err(ApiError::unauthorized("Sesi milik pengguna lain."));
        }
        if session.expires_at < now {
            return Err(ApiError::conflict_named(
                "SESSION_EXPIRED",
                "Sesi Kedaluwarsa",
                "Sesi pelajaran sudah kedaluwarsa, mulai sesi baru.",
            ));
        }
    }

    let summary = state.storage.write(|s| {
        let lesson_id = match &session {
            Some(session) => session.lesson_id,
            None => s.lesson_of_node(payload.node_id)?.id,
        };
        let duration = if payload.duration_ms > 0 {
            payload.duration_ms
        } else {
            (now - payload.started_at).num_milliseconds().max(0)
        };
        let summary = lq_db::learning::commit_session(
            s,
            user.user_id,
            payload.node_id,
            lesson_id,
            payload.started_at,
            now,
            duration,
            payload.client_op_id,
            &payload.answers,
        );
        if let Some(session_id) = payload.session_id {
            s.sessions.remove(&session_id);
        }
        summary
    });

    let summary = summary.ok_or_else(|| ApiError::not_found("Pelajaran tidak ditemukan."))?;
    state.commit(Some(user.user_id)).await?;
    Ok(Json(summary))
}
