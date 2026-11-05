//! Kurikulum & detail pelajaran.

use axum::extract::{Path, State};
use axum::Json;
use lq_types::{CourseDto, CurriculumDto, LessonDetailDto};
use uuid::Uuid;

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub async fn courses(State(state): State<AppState>) -> ApiResult<Vec<CourseDto>> {
    let courses = state.storage.read(|s| {
        s.courses
            .iter()
            .map(|c| CourseDto {
                id: c.id,
                from_lang: c.from_lang.clone(),
                to_lang: c.to_lang.clone(),
                title: c.title.clone(),
                version: c.version,
            })
            .collect::<Vec<_>>()
    });
    Ok(Json(courses))
}

pub async fn curriculum(
    State(state): State<AppState>,
    user: AuthUser,
    Path(course_id): Path<Uuid>,
) -> ApiResult<CurriculumDto> {
    let curriculum = state
        .storage
        .read(|s| lq_db::curriculum::curriculum(s, user.user_id, course_id));
    curriculum
        .map(Json)
        .ok_or_else(|| ApiError::not_found("Kurikulum tidak ditemukan."))
}

pub async fn lesson(
    State(state): State<AppState>,
    user: AuthUser,
    Path(node_id): Path<Uuid>,
) -> ApiResult<LessonDetailDto> {
    let lesson = state
        .storage
        .read(|s| lq_db::curriculum::lesson(s, user.user_id, node_id));
    lesson.map(Json).ok_or_else(|| {
        ApiError::forbidden(
            "NODE_LOCKED",
            "Node Terkunci",
            "Selesaikan node sebelumnya terlebih dahulu.",
        )
    })
}
