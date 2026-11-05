//! Proyeksi kurikulum ke DTO klien (status node dihitung per pengguna).

use lq_types::{
    CourseDto, CurriculumDto, Exercise, ExerciseDto, GuidebookDto, LessonDetailDto, LessonNodeDto,
    NodeStatus, UnitDto,
};
use uuid::Uuid;

use crate::db::DbState;

pub fn to_exercise_dto(exercise: &Exercise) -> ExerciseDto {
    ExerciseDto {
        id: exercise.id,
        kind: exercise.kind,
        position: exercise.position,
        prompt: exercise.prompt.clone(),
        instruction: exercise.instruction.clone(),
        translation: exercise.translation.clone(),
        audio_url: exercise.audio_url.clone(),
        options: exercise.options.clone(),
        word_bank: exercise.word_bank.clone(),
        pairs: exercise.pairs.clone(),
    }
}

fn guidebook(value: &serde_json::Value) -> GuidebookDto {
    GuidebookDto {
        summary: value["summary"].as_str().unwrap_or_default().to_string(),
        grammar_tips: value["grammarTips"]
            .as_array()
            .map(|items| items.iter().filter_map(|i| i.as_str().map(str::to_string)).collect())
            .unwrap_or_default(),
    }
}

pub fn curriculum(state: &DbState, user_id: Uuid, course_id: Uuid) -> Option<CurriculumDto> {
    let course = state.course(course_id)?;
    let units = state
        .units_of_course(course_id)
        .into_iter()
        .map(|unit| {
            let nodes = state
                .nodes_of_unit(unit.id)
                .into_iter()
                .map(|node| {
                    let progress = state.progress.get(&(user_id, node.id));
                    let completed = progress.map(|p| p.status == "completed").unwrap_or(false);
                    let mastered = progress.map(|p| p.mastered).unwrap_or(false);
                    let unlocked_position = state.unlocked_position(user_id, node.id);
                    let unlocked = node.position <= unlocked_position;
                    let exercises = state.node_exercises(node.id);
                    let status = if completed {
                        NodeStatus::Completed
                    } else if unlocked {
                        NodeStatus::Current
                    } else {
                        NodeStatus::Locked
                    };
                    LessonNodeDto {
                        id: node.id,
                        kind: node.kind.clone(),
                        title: node.title.clone(),
                        description: node.description.clone(),
                        position: node.position,
                        lesson_id: state.lesson_of_node(node.id).map(|l| l.id),
                        total_exercises: exercises.len() as i32,
                        status,
                        is_mastered: mastered,
                        current_position: unlocked_position,
                        exercises: exercises.iter().map(to_exercise_dto).collect(),
                    }
                })
                .collect();

            UnitDto {
                id: unit.id,
                position: unit.position,
                title: unit.title.clone(),
                description: unit.description.clone(),
                theme_color: unit.theme_color.clone(),
                guidebook: guidebook(&unit.guidebook),
                nodes,
            }
        })
        .collect();

    Some(CurriculumDto {
        course: CourseDto {
            id: course.id,
            from_lang: course.from_lang.clone(),
            to_lang: course.to_lang.clone(),
            title: course.title.clone(),
            version: course.version,
        },
        units,
    })
}

pub fn lesson(state: &DbState, user_id: Uuid, node_id: Uuid) -> Option<LessonDetailDto> {
    let node = state.node(node_id)?;
    if node.position > state.unlocked_position(user_id, node_id) {
        return None;
    }
    let lesson = state.lesson_of_node(node_id)?;
    let exercises = state.lesson_exercises(lesson.id);
    Some(LessonDetailDto {
        lesson_id: lesson.id,
        node_id,
        title: node.title.clone(),
        exercises: exercises.iter().map(to_exercise_dto).collect(),
    })
}

pub fn default_course_id(state: &DbState) -> Option<Uuid> {
    state.courses.first().map(|c| c.id)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{seed, Storage};

    #[test]
    fn first_node_is_current_others_locked() {
        let mut state = DbState::default();
        seed::seed_curriculum(&mut state);
        let storage = Storage::memory_with_state(state);
        let user = Uuid::new_v4();
        let course_id = storage.read(|s| default_course_id(s).unwrap());
        let curriculum = storage.read(|s| curriculum(s, user, course_id).unwrap());
        let statuses: Vec<NodeStatus> = curriculum.units[0].nodes.iter().map(|n| n.status).collect();
        assert_eq!(statuses[0], NodeStatus::Current);
        assert_eq!(statuses[1], NodeStatus::Locked);
        assert_eq!(curriculum.units[1].nodes[0].status, NodeStatus::Locked);
    }

    #[test]
    fn exercises_never_leak_answers() {
        let mut state = DbState::default();
        seed::seed_curriculum(&mut state);
        let storage = Storage::memory_with_state(state);
        let user = Uuid::new_v4();
        let course_id = storage.read(|s| default_course_id(s).unwrap());
        let curriculum = storage.read(|s| curriculum(s, user, course_id).unwrap());
        let json = serde_json::to_string(&curriculum).unwrap();
        assert!(!json.contains("correctAnswer"));
        assert!(!json.contains("acceptableAnswers"));
    }
}
