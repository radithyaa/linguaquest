//! API yang diekspos ke Dart (native C-FFI & WASM).

use chrono::{DateTime, Utc};
use lq_core::{
    calculate_xp, check_answer, next_interval, process_fsrs_review, regenerate_hearts,
    retrievability, update_streak, EvaluationResult,
};
use lq_types::{AnswerEvaluation, EvaluationStatus, SrsCard, UserStats};

fn to_evaluation(status: EvaluationStatus, canonical: &str, distance: i32) -> AnswerEvaluation {
    AnswerEvaluation {
        status,
        canonical_answer: canonical.to_string(),
        distance,
    }
}

/// Evaluasi jawaban pengguna dengan normalisasi NFKD + toleransi typo
/// Levenshtein <= 2 (SRS EXE-01 s/d EXE-05).
#[flutter_rust_bridge::frb(sync)]
pub fn evaluate_answer(
    input: String,
    correct_answer: String,
    acceptable_answers: Vec<String>,
) -> AnswerEvaluation {
    match check_answer(&input, &correct_answer, &acceptable_answers) {
        EvaluationResult::Correct => {
            to_evaluation(EvaluationStatus::Correct, &correct_answer, 0)
        }
        EvaluationResult::TypoWarning(canonical) => {
            let distance =
                lq_core::levenshtein_distance(&lq_core::normalize_text(&input), &lq_core::normalize_text(&canonical))
                    as i32;
            to_evaluation(EvaluationStatus::TypoWarning, &canonical, distance)
        }
        EvaluationResult::Incorrect => to_evaluation(EvaluationStatus::Incorrect, &correct_answer, -1),
    }
}

/// Normalisasi teks (dipakai untuk validasi input di klien).
#[flutter_rust_bridge::frb(sync)]
pub fn normalize(input: String) -> String {
    lq_core::normalize_text(&input)
}

/// Perhitungan XP sesuai SRS 9.1.
#[flutter_rust_bridge::frb(sync)]
pub fn compute_xp(accuracy: f64, max_combo: i32) -> i32 {
    calculate_xp(accuracy as f32, max_combo)
}

/// Proyeksi interval kartu FSRS setelah rating (untuk label UI "besok", "3 hari").
#[flutter_rust_bridge::frb(sync)]
pub fn fsrs_preview(stability: f64, rating: i32) -> f64 {
    let mut card = SrsCard {
        id: uuid::Uuid::nil(),
        user_id: uuid::Uuid::nil(),
        word: String::new(),
        translation: String::new(),
        stability: stability as f32,
        difficulty: 5.0,
        due_at: Utc::now(),
        last_review: Some(Utc::now()),
        reps: if stability > 0.0 { 1 } else { 0 },
        lapses: 0,
    };
    let rating = lq_types::FsrsRating::from_i32(rating).unwrap_or(lq_types::FsrsRating::Good);
    process_fsrs_review(&mut card, rating, Utc::now());
    card.stability as f64
}

/// Durabilitas memori saat ini (0.0 - 1.0).
#[flutter_rust_bridge::frb(sync)]
pub fn current_retrievability(elapsed_days: f64, stability: f64) -> f64 {
    retrievability(elapsed_days as f32, stability as f32) as f64
}

/// Interval ideal yang direkomendasikan FSRS 4.5 untuk target retensi 90%.
#[flutter_rust_bridge::frb(sync)]
pub fn recommended_interval_days(stability: f64) -> f64 {
    next_interval(stability as f32, 0.90) as f64
}

/// Aplikasikan rating FSRS pada kartu (state lokal offline).
pub fn apply_fsrs_rating(card: SrsCard, rating: i32) -> Result<SrsCard, String> {
    let rating = lq_types::FsrsRating::from_i32(rating)
        .ok_or_else(|| "rating harus bernilai 1..4".to_string())?;
    let mut updated = card;
    process_fsrs_review(&mut updated, rating, Utc::now());
    Ok(updated)
}

/// Hitung ulang heart berdasarkan waktu terakhir pembaruan (1 heart / 4 jam).
#[flutter_rust_bridge::frb(sync)]
pub fn refresh_hearts(hearts: i32, hearts_updated_at: String, now_iso: String) -> String {
    let Ok(last) = DateTime::parse_from_rfc3339(&hearts_updated_at) else {
        return "{}".to_string();
    };
    let Ok(now) = DateTime::parse_from_rfc3339(&now_iso) else {
        return "{}".to_string();
    };
    let (hearts, updated_at) =
        regenerate_hearts(hearts, last.with_timezone(&Utc), now.with_timezone(&Utc));
    serde_json::json!({
        "hearts": hearts,
        "heartsUpdatedAt": updated_at.to_rfc3339(),
    })
    .to_string()
}

/// Perbarui streak harian terhadap stats lokal.
#[flutter_rust_bridge::frb(sync)]
pub fn apply_streak(stats: UserStats, today: String, daily_xp_today: i32) -> UserStats {
    let mut updated = stats;
    update_streak(&mut updated, &today, daily_xp_today);
    updated
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn evaluate_accepts_typo() {
        let result = evaluate_answer("tehcer".into(), "teacher".into(), vec![]);
        assert_eq!(result.status, EvaluationStatus::TypoWarning);
        assert_eq!(result.distance, 2);
    }

    #[test]
    fn evaluate_rejects_wrong() {
        let result = evaluate_answer("xyz".into(), "teacher".into(), vec![]);
        assert_eq!(result.status, EvaluationStatus::Incorrect);
    }

    #[test]
    fn evaluate_accepts_alternative() {
        let result = evaluate_answer("guten tag".into(), "halo".into(), vec!["guten tag".into()]);
        assert_eq!(result.status, EvaluationStatus::Correct);
    }

    #[test]
    fn xp_matches_srs_formula() {
        assert_eq!(compute_xp(1.0, 15), 21);
    }
}
