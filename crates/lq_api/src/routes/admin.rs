//! Admin CMS: menambah unit & node kurikulum (SRS ADM).

use axum::extract::{Path, State};
use axum::Json;
use chrono::Utc;
use lq_types::{CreateNodeRequest, CreateUnitRequest, UnitDto};
use uuid::Uuid;

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

fn require_admin(state: &AppState, user_id: Uuid) -> Result<(), ApiError> {
    let is_admin = state
        .storage
        .read(|s| s.users.get(&user_id).map(|u| u.role == "admin").unwrap_or(false));
    if is_admin {
        Ok(())
    } else {
        Err(ApiError::forbidden(
            "ADMIN_ONLY",
            "Akses Ditolak",
            "Endpoint ini hanya untuk akun administrator. Set role = 'admin' pada tabel users.",
        ))
    }
}

pub async fn create_unit(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<CreateUnitRequest>,
) -> ApiResult<UnitDto> {
    require_admin(&state, user.user_id)?;
    if payload.title.trim().is_empty() {
        return Err(ApiError::bad_request("Judul unit wajib diisi."));
    }

    let unit = state.storage.write(|s| -> Option<lq_db::db::UnitRow> {
        let course_id = match payload.course_id {
            Some(id) => id,
            None => s.courses.first()?.id,
        };
        let position = s
            .units
            .iter()
            .filter(|u| u.course_id == course_id)
            .map(|u| u.position)
            .max()
            .unwrap_or(0)
            + 1;
        let unit = lq_db::db::UnitRow {
            id: Uuid::new_v4(),
            course_id,
            position,
            title: payload.title.clone(),
            description: payload.description.clone(),
            theme_color: payload.theme_color.clone().unwrap_or_else(|| "#58CC02".into()),
            guidebook: serde_json::json!({
                "summary": payload.summary,
                "grammarTips": payload.grammar_tips,
            }),
        };
        s.units.push(unit.clone());
        Some(unit)
    });

    let unit = unit.ok_or_else(|| ApiError::not_found("Belum ada course yang tersedia."))?;
    state.commit(None).await?;
    Ok(Json(UnitDto {
        id: unit.id,
        position: unit.position,
        title: unit.title,
        description: unit.description,
        theme_color: unit.theme_color,
        guidebook: lq_types::GuidebookDto {
            summary: unit.guidebook["summary"].as_str().unwrap_or_default().to_string(),
            grammar_tips: unit.guidebook["grammarTips"]
                .as_array()
                .map(|items| items.iter().filter_map(|i| i.as_str().map(str::to_string)).collect())
                .unwrap_or_default(),
        },
        nodes: vec![],
    }))
}

pub async fn create_node(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<CreateNodeRequest>,
) -> ApiResult<serde_json::Value> {
    require_admin(&state, user.user_id)?;
    if payload.exercises.is_empty() {
        return Err(ApiError::bad_request("Minimal satu latihan diperlukan."));
    }

    let created = state.storage.write(|s| {
        if s.unit(payload.unit_id).is_none() {
            return None;
        }
        let position = s
            .nodes
            .iter()
            .filter(|n| n.unit_id == payload.unit_id)
            .map(|n| n.position)
            .max()
            .unwrap_or(0)
            + 1;
        let node_id = Uuid::new_v4();
        let lesson_id = Uuid::new_v4();
        s.nodes.push(lq_db::db::NodeRow {
            id: node_id,
            unit_id: payload.unit_id,
            position,
            kind: payload.kind.clone().unwrap_or_else(|| "lesson".into()),
            title: payload.title.clone(),
            description: payload.description.clone(),
        });
        s.lessons.push(lq_db::db::LessonRow { id: lesson_id, node_id, position: 1 });

        let exercises = payload
            .exercises
            .iter()
            .enumerate()
            .map(|(index, item)| lq_types::Exercise {
                id: Uuid::new_v4(),
                lesson_id: Some(lesson_id),
                kind: item.kind,
                position: (index + 1) as i32,
                prompt: item.prompt.clone(),
                instruction: item.instruction.clone(),
                translation: Some(item.correct_answer.clone()),
                audio_url: None,
                options: item.options.clone(),
                correct_answer: item.correct_answer.clone(),
                acceptable_answers: item.acceptable_answers.clone(),
                word_bank: item.word_bank.clone(),
                pairs: item.pairs.clone(),
                explanation: item.explanation.clone(),
            })
            .collect();
        s.exercises.insert(lesson_id, exercises);
        Some(serde_json::json!({
            "nodeId": node_id,
            "lessonId": lesson_id,
            "position": position,
            "createdAt": Utc::now(),
        }))
    });

    let created = created.ok_or_else(|| ApiError::not_found("Unit tidak ditemukan."))?;
    state.commit(None).await?;
    Ok(Json(created))
}

pub async fn delete_unit(
    State(state): State<AppState>,
    user: AuthUser,
    Path(unit_id): Path<Uuid>,
) -> ApiResult<serde_json::Value> {
    require_admin(&state, user.user_id)?;
    let removed = state.storage.write(|s| {
        let before = s.units.len();
        s.units.retain(|u| u.id != unit_id);
        let node_ids: Vec<Uuid> = s.nodes.iter().filter(|n| n.unit_id == unit_id).map(|n| n.id).collect();
        s.nodes.retain(|n| n.unit_id != unit_id);
        for node_id in node_ids {
            if let Some(lesson) = s.lesson_of_node(node_id).cloned() {
                s.exercises.remove(&lesson.id);
                s.lessons.retain(|l| l.id != lesson.id);
            }
        }
        s.units.len() != before
    });

    if !removed {
        return Err(ApiError::not_found("Unit tidak ditemukan."));
    }
    state.commit(None).await?;
    Ok(Json(serde_json::json!({ "success": true })))
}
