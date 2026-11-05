use chrono::{DateTime, Duration, Utc};
use lq_types::{FsrsRating, SrsCard};

/// FSRS 4.5 parameters default values
pub const FACTOR_F: f32 = 19.0 / 81.0; // 0.2345679
pub const REQUESTED_RETENTION: f32 = 0.90;

/// Calculate retrievability R(t) = (1 + F * (t / S)) ^ -1
pub fn retrievability(elapsed_days: f32, stability: f32) -> f32 {
    if stability <= 0.0 {
        return 0.0;
    }
    (1.0 + FACTOR_F * (elapsed_days / stability)).powf(-1.0)
}

/// Calculate next interval in days when retrievability reaches requested retention (e.g. 90%)
pub fn next_interval(stability: f32, desired_retention: f32) -> f32 {
    if stability <= 0.0 {
        return 1.0;
    }
    (stability / FACTOR_F) * ((1.0 / desired_retention) - 1.0)
}

/// Update SRS card according to FSRS 4.5 rating
pub fn process_fsrs_review(
    card: &mut SrsCard,
    rating: FsrsRating,
    now: DateTime<Utc>,
) {
    let elapsed_days = match card.last_review {
        Some(last) => {
            let dur = now.signed_duration_since(last);
            (dur.num_minutes() as f32 / 1440.0).max(0.0)
        }
        None => 0.0,
    };

    let r = if card.reps == 0 {
        1.0
    } else {
        retrievability(elapsed_days, card.stability)
    };

    // Update Difficulty (D)
    let d_delta = match rating {
        FsrsRating::Again => 0.8,
        FsrsRating::Hard => 0.3,
        FsrsRating::Good => 0.0,
        FsrsRating::Easy => -0.4,
    };
    card.difficulty = (card.difficulty + d_delta).clamp(1.0, 10.0);

    // Update Stability (S)
    let new_stability = match rating {
        FsrsRating::Again => {
            card.lapses += 1;
            (card.stability * 0.4).max(0.5)
        }
        FsrsRating::Hard => card.stability * (1.0 + 0.15 * (1.0 - r)),
        FsrsRating::Good => card.stability * (1.0 + 0.35 * (1.0 - r)),
        FsrsRating::Easy => card.stability * (1.0 + 0.60 * (1.0 - r)) * 1.3,
    };

    card.stability = if card.reps == 0 {
        match rating {
            FsrsRating::Again => 0.6,
            FsrsRating::Hard => 1.2,
            FsrsRating::Good => 2.5,
            FsrsRating::Easy => 4.0,
        }
    } else {
        new_stability.clamp(0.1, 3650.0)
    };

    card.reps += 1;
    card.last_review = Some(now);

    let days = next_interval(card.stability, REQUESTED_RETENTION).max(1.0);
    card.due_at = now + Duration::seconds((days * 86400.0) as i64);
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_initial_review_good() {
        let now = Utc::now();
        let mut card = SrsCard {
            id: Uuid::new_v4(),
            user_id: Uuid::new_v4(),
            word: "halo".to_string(),
            translation: "hello".to_string(),
            stability: 0.0,
            difficulty: 5.0,
            due_at: now,
            last_review: None,
            reps: 0,
            lapses: 0,
        };

        process_fsrs_review(&mut card, FsrsRating::Good, now);
        assert_eq!(card.reps, 1);
        assert_eq!(card.stability, 2.5);
        assert!(card.due_at > now);
    }
}
