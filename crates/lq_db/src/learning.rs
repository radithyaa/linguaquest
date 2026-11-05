//! Mesin evaluasi sesi pelajaran: validasi jawaban, combo, XP, hearts,
//! `node_progress`, mistake log, dan pembaruan kartu SRS.

use chrono::{DateTime, NaiveDate, Utc};
use lq_core::{calculate_xp, check_answer, EvaluationResult};
use lq_types::{
    AnswerResultDto, AnswerSubmission, Exercise, ExerciseKind, FsrsRating, NodeStatus,
    SessionSummaryDto,
};
use uuid::Uuid;

use crate::db::{AttemptRow, DbState, MistakeRow, ProgressRow, StatsRow};
use crate::users::to_stats_dto;

pub const GEMS_PER_LESSON: i32 = 5;

/// Batas kemiripan transkripsi STT untuk latihan pelafalan (EXE-07).
pub const SPEECH_SIMILARITY_THRESHOLD: f64 = 0.70;

pub fn speech_similarity(expected: &str, spoken: &str) -> f64 {
    let expected = lq_core::normalize_text(expected);
    let spoken = lq_core::normalize_text(spoken);
    if expected.is_empty() || spoken.is_empty() {
        return 0.0;
    }
    let max_len = expected.chars().count().max(spoken.chars().count());
    let distance = lq_core::levenshtein_distance(&expected, &spoken);
    (1.0 - (distance as f64 / max_len as f64)).max(0.0)
}

pub fn status_string(status: NodeStatus) -> String {
    match status {
        NodeStatus::Locked => "locked",
        NodeStatus::Current => "current",
        NodeStatus::Completed => "completed",
    }
    .to_string()
}

/// Evaluasi satu jawaban. Mengembalikan `(benar, DTO hasil)`.
pub fn evaluate(exercise: &Exercise, answer: &str) -> (bool, AnswerResultDto) {
    let (is_correct, typo, canonical) = match exercise.kind {
        ExerciseKind::PairMatching => {
            let submitted: Vec<(String, String)> = answer
                .split('|')
                .filter_map(|pair| pair.split_once('='))
                .map(|(left, right)| (left.trim().to_lowercase(), right.trim().to_lowercase()))
                .collect();
            let expected: Vec<(String, String)> = exercise
                .pairs
                .iter()
                .map(|p| (p.left.to_lowercase(), p.right.to_lowercase()))
                .collect();
            let ok = !expected.is_empty() && expected.iter().all(|pair| submitted.contains(pair));
            (ok, false, exercise.correct_answer.clone())
        }
        ExerciseKind::Speech => {
            let similarity = speech_similarity(&exercise.correct_answer, answer);
            (similarity >= SPEECH_SIMILARITY_THRESHOLD, false, exercise.correct_answer.clone())
        }
        _ => match check_answer(answer, &exercise.correct_answer, &exercise.acceptable_answers) {
            EvaluationResult::Correct => (true, false, exercise.correct_answer.clone()),
            EvaluationResult::TypoWarning(canonical) => (true, true, canonical),
            EvaluationResult::Incorrect => (false, false, exercise.correct_answer.clone()),
        },
    };

    (
        is_correct,
        AnswerResultDto {
            exercise_id: exercise.id,
            is_correct,
            accepted: is_correct,
            typo_warning: typo,
            correct_answer: canonical,
            explanation: exercise.explanation.clone(),
        },
    )
}

pub struct EvaluationOutcome {
    pub correct_count: i32,
    pub total: i32,
    pub max_combo: i32,
    pub hearts_lost: i32,
    pub xp: i32,
    pub answers: Vec<AnswerResultDto>,
    pub mistakes: Vec<MistakeRow>,
}

pub fn evaluate_session(
    user_id: Uuid,
    exercises: &[Exercise],
    answers: &[AnswerSubmission],
    now: DateTime<Utc>,
) -> EvaluationOutcome {
    let by_id: std::collections::HashMap<Uuid, &Exercise> =
        exercises.iter().map(|e| (e.id, e)).collect();

    let mut correct_count = 0;
    let mut combo = 0;
    let mut max_combo = 0;
    let mut hearts_lost = 0;
    let mut results = Vec::new();
    let mut mistakes = Vec::new();

    for submission in answers {
        let Some(exercise) = by_id.get(&submission.exercise_id) else {
            continue;
        };
        let (is_correct, dto) = evaluate(exercise, &submission.answer);
        if is_correct {
            correct_count += 1;
            combo += 1;
            max_combo = max_combo.max(combo);
        } else {
            combo = 0;
            hearts_lost += 1;
            mistakes.push(MistakeRow {
                user_id,
                exercise_id: exercise.id,
                prompt: exercise.prompt.clone(),
                correct_answer: exercise.correct_answer.clone(),
                your_answer: submission.answer.clone(),
                occurred_at: now,
                reviewed_at: None,
            });
        }
        results.push(dto);
    }

    let total = exercises.len() as i32;
    let accuracy = if total > 0 { correct_count as f64 / total as f64 } else { 0.0 };
    let xp = calculate_xp(accuracy as f32, max_combo);

    EvaluationOutcome {
        correct_count,
        total,
        max_combo,
        hearts_lost,
        xp,
        answers: results,
        mistakes,
    }
}

/// Terapkan hasil sesi ke state dalam satu operasi atomik.
/// Mengembalikan `None` jika node/pelajaran tidak ditemukan atau operasi duplikat.
#[allow(clippy::too_many_arguments)]
pub fn commit_session(
    state: &mut DbState,
    user_id: Uuid,
    node_id: Uuid,
    lesson_id: Uuid,
    started_at: DateTime<Utc>,
    completed_at: DateTime<Utc>,
    duration_ms: i64,
    client_op_id: Uuid,
    answers: &[AnswerSubmission],
) -> Option<SessionSummaryDto> {
    if state.applied_ops.contains(&client_op_id) {
        return None;
    }

    let exercises = state.lesson_exercises(lesson_id);
    if exercises.is_empty() {
        return None;
    }

    let outcome = evaluate_session(user_id, &exercises, answers, completed_at);
    let now = completed_at;
    let accuracy = outcome.correct_count as f64 / outcome.total.max(1) as f64;

    // 1. Catat attempt (idempotent terhadap client_op_id).
    state.attempts.push(AttemptRow {
        id: Uuid::new_v4(),
        user_id,
        lesson_id,
        node_id,
        started_at,
        completed_at,
        accuracy,
        correct_count: outcome.correct_count,
        total_questions: outcome.total,
        max_combo: outcome.max_combo,
        xp_awarded: outcome.xp,
        hearts_lost: outcome.hearts_lost,
        duration_ms,
        client_op_id,
        answers_json: serde_json::to_value(&outcome.answers).unwrap_or_default(),
    });
    state.applied_ops.insert(client_op_id);

    // 2. Progres node + pembukaan node berikutnya.
    let mut is_mastered = false;
    if let Some(node) = state.node(node_id).cloned() {
        let entry = state
            .progress
            .entry((user_id, node_id))
            .or_insert_with(|| ProgressRow {
                status: status_string(NodeStatus::Current),
                updated_at: Some(now),
                ..Default::default()
            });
        entry.attempts += 1;
        entry.best_accuracy = entry.best_accuracy.max(accuracy);
        entry.mastered = entry.mastered || accuracy >= 1.0;
        entry.status = status_string(NodeStatus::Completed);
        entry.updated_at = Some(now);
        is_mastered = entry.mastered;

        let next_node = state
            .nodes_of_unit(node.unit_id)
            .into_iter()
            .find(|n| n.position == node.position + 1)
            .map(|n| n.id);
        if let Some(next_id) = next_node {
            state.progress.entry((user_id, next_id)).or_insert_with(|| ProgressRow {
                status: status_string(NodeStatus::Current),
                updated_at: Some(now),
                ..Default::default()
            });
        }
    }

    // 3. Mistake log.
    for mistake in outcome.mistakes {
        state.mistakes.insert((user_id, mistake.exercise_id), mistake);
    }

    // 4. Kartu SRS dibuat/di-refresh untuk kosakata sesi ini.
    for exercise in &exercises {
        match exercise.kind {
            ExerciseKind::MultipleChoice | ExerciseKind::Typing | ExerciseKind::Listening => {
                crate::srs::card_for(state, user_id, &exercise.prompt, &exercise.correct_answer);
            }
            ExerciseKind::WordBank
            | ExerciseKind::FillInTheBlank
            | ExerciseKind::PairMatching
            | ExerciseKind::Speech => {
                for pair in &exercise.pairs {
                    crate::srs::card_for(state, user_id, &pair.left, &pair.right);
                }
            }
            _ => {}
        }
    }

    // 5. XP, gems, level, hearts, streak.
    let gems_earned = GEMS_PER_LESSON + outcome.correct_count / 2;
    let local_date = now.date_naive();
    let today_xp = state.xp_on(user_id, local_date) + outcome.xp;

    let stats_snapshot = {
        let mut stats = state.stats.get(&user_id).cloned()?;
        stats.total_xp += outcome.xp as i64;
        stats.level = DbState::level_for_xp(stats.total_xp);
        stats.gems += gems_earned;
        if outcome.hearts_lost > 0 {
            stats.hearts = (stats.hearts - outcome.hearts_lost).max(0);
            stats.hearts_updated_at = now;
        }
        apply_streak(&mut stats, local_date, today_xp);
        state.stats.insert(user_id, stats.clone());
        stats
    };

    // 6. Quest harian & XP liga mingguan.
    crate::quests::record_session(state, user_id, local_date, accuracy);
    crate::league::add_weekly_xp(state, user_id, outcome.xp as i64);

    Some(SessionSummaryDto {
        session_id: Uuid::new_v4(),
        lesson_id,
        node_id,
        total_questions: outcome.total,
        correct_count: outcome.correct_count,
        accuracy,
        max_combo: outcome.max_combo,
        xp_earned: outcome.xp,
        gems_earned,
        hearts_lost: outcome.hearts_lost,
        duration_ms,
        is_mastered,
        streak: stats_snapshot.streak,
        stats: to_stats_dto(state, &stats_snapshot, now),
        answers: outcome.answers,
    })
}

/// Hitung streak harian memakai logika `lq_core` (target harian, Streak Freeze).
fn apply_streak(stats: &mut StatsRow, local_date: NaiveDate, xp_today: i32) {
    if let Some(last) = stats.last_active_date {
        if last > local_date {
            return; // Jam mundur / perbedaan zona waktu: jangan turunkan data.
        }
    }

    let today = local_date.to_string();
    let mut probe = lq_types::UserStats {
        user_id: stats.user_id,
        total_xp: stats.total_xp,
        level: stats.level,
        streak: stats.streak,
        longest_streak: stats.longest_streak,
        last_active_date: stats.last_active_date.map(|d| d.to_string()),
        hearts: stats.hearts,
        hearts_updated_at: stats.hearts_updated_at,
        gems: stats.gems,
        freezes_available: stats.freezes_available,
        daily_goal_xp: stats.daily_goal_xp,
        xp_today,
        next_heart_seconds: 0,
    };

    if xp_today >= stats.daily_goal_xp {
        lq_core::update_streak(&mut probe, &today, xp_today);
    } else {
        probe.last_active_date = Some(today);
    }

    stats.streak = probe.streak;
    stats.longest_streak = probe.longest_streak;
    stats.freezes_available = probe.freezes_available;
    stats.last_active_date = probe.last_active_date.as_deref().and_then(|d| d.parse().ok());
}

/// Digunakan oleh review FSRS (memastikan rating valid sebelum diterapkan).
pub fn parse_rating(value: i32) -> Option<FsrsRating> {
    FsrsRating::from_i32(value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use lq_types::MatchingPair;

    fn exercise(kind: ExerciseKind, correct: &str) -> Exercise {
        Exercise {
            id: Uuid::new_v4(),
            lesson_id: None,
            kind,
            position: 1,
            prompt: "p".into(),
            instruction: None,
            translation: None,
            audio_url: None,
            options: vec![],
            correct_answer: correct.into(),
            acceptable_answers: vec![],
            word_bank: vec![],
            pairs: vec![],
            explanation: None,
        }
    }

    #[test]
    fn multiple_choice_requires_exact_meaning() {
        let ex = exercise(ExerciseKind::MultipleChoice, "Halo");
        assert!(evaluate(&ex, "Halo").0);
        assert!(!evaluate(&ex, "Selamat tinggal").0);
    }

    #[test]
    fn typing_tolerates_typo() {
        let ex = exercise(ExerciseKind::Typing, "Terima kasih banyak");
        let (ok, result) = evaluate(&ex, "Terima kasih banyk");
        assert!(ok);
        assert!(result.typo_warning);
    }

    #[test]
    fn pair_matching_requires_all_pairs() {
        let mut ex = exercise(ExerciseKind::PairMatching, "");
        ex.pairs = vec![
            MatchingPair { left: "Hello".into(), right: "Halo".into() },
            MatchingPair { left: "Tea".into(), right: "Teh".into() },
        ];
        assert!(evaluate(&ex, "Hello=Halo|Tea=Teh").0);
        assert!(!evaluate(&ex, "Hello=Halo").0);
    }

    #[test]
    fn speech_uses_similarity_threshold() {
        let ex = exercise(ExerciseKind::Speech, "Nice to meet you");
        assert!(evaluate(&ex, "nice to meet you").0);
        assert!(evaluate(&ex, "nice to met you").0);
        assert!(!evaluate(&ex, "komputer").0);
    }

    #[test]
    fn perfect_session_matches_srs_xp_formula() {
        let ex = exercise(ExerciseKind::Typing, "halo");
        let answers: Vec<AnswerSubmission> = (0..10)
            .map(|_| AnswerSubmission { exercise_id: ex.id, answer: "halo".into(), duration_ms: 100 })
            .collect();
        let exercises: Vec<Exercise> = (0..10).map(|_| ex.clone()).collect();
        let outcome = evaluate_session(Uuid::new_v4(), &exercises, &answers, Utc::now());
        assert_eq!(outcome.correct_count, 10);
        assert_eq!(outcome.max_combo, 10);
        assert_eq!(outcome.xp, 19); // 10 base + 5 akurasi + 4 combo
    }

    #[test]
    fn commit_is_idempotent_and_awards_progress() {
        let mut state = DbState::default();
        crate::seed::seed_curriculum(&mut state);
        let user_id = Uuid::new_v4();
        state.stats.insert(user_id, StatsRow::new(user_id));
        let node_id = Uuid::parse_str(crate::seed::NODE_U1_1).unwrap();
        let lesson_id = state.lesson_of_node(node_id).unwrap().id;
        let exercises = state.lesson_exercises(lesson_id);
        let answers: Vec<AnswerSubmission> = exercises
            .iter()
            .map(|e| AnswerSubmission { exercise_id: e.id, answer: e.correct_answer.clone(), duration_ms: 100 })
            .collect();
        let op = Uuid::new_v4();

        let summary = commit_session(
            &mut state, user_id, node_id, lesson_id, Utc::now(), Utc::now(), 5000, op, &answers,
        )
        .expect("sesi pertama harus diproses");
        assert_eq!(summary.correct_count, summary.total_questions);
        assert_eq!(summary.stats.hearts, 5);
        assert!(state.is_completed(user_id, node_id));

        let duplicate = commit_session(
            &mut state, user_id, node_id, lesson_id, Utc::now(), Utc::now(), 5000, op, &answers,
        );
        assert!(duplicate.is_none(), "operasi duplikat harus diabaikan");
    }
}
