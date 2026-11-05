//! Ulasan berulang FSRS 4.5 (kartu kosakata).

use chrono::{DateTime, Utc};
use lq_core::{next_interval, retrievability};
use lq_types::{FsrsRating, MistakeDto, PracticeOverviewDto, SrsCard, SrsCardDto};
use uuid::Uuid;

use crate::db::DbState;

/// Ambil kartu dengan membuatnya bila belum ada (kosakata unit 1 & 2).
pub fn card_for(state: &mut DbState, user_id: Uuid, word: &str, translation: &str) -> SrsCard {
    let key = (user_id, word.to_lowercase());
    if let Some(existing) = state.cards.get(&key) {
        return existing.clone();
    }
    let card = SrsCard {
        id: Uuid::new_v4(),
        user_id,
        word: word.to_string(),
        translation: translation.to_string(),
        stability: 0.0,
        difficulty: 5.0,
        due_at: Utc::now(),
        last_review: None,
        reps: 0,
        lapses: 0,
    };
    state.cards.insert(key, card.clone());
    card
}

pub fn to_dto(card: &SrsCard, now: DateTime<Utc>) -> SrsCardDto {
    let elapsed_days = card
        .last_review
        .map(|last| (now - last).num_minutes().max(0) as f32 / 1440.0)
        .unwrap_or(0.0);
    SrsCardDto {
        id: card.id,
        word: card.word.clone(),
        translation: card.translation.clone(),
        stability: card.stability,
        difficulty: card.difficulty,
        due_at: card.due_at,
        reps: card.reps,
        lapses: card.lapses,
        retrievability: retrievability(elapsed_days, card.stability),
        interval_days: next_interval(card.stability, 0.90),
    }
}

pub fn review(state: &mut DbState, user_id: Uuid, card_id: Uuid, rating: i32, now: DateTime<Utc>) -> Option<SrsCard> {
    let rating = FsrsRating::from_i32(rating)?;
    let key = state
        .cards
        .iter()
        .find(|((uid, _), card)| *uid == user_id && card.id == card_id)
        .map(|(key, _)| key.clone())?;
    let mut card = state.cards.get(&key)?.clone();
    lq_core::process_fsrs_review(&mut card, rating, now);
    state.cards.insert(key, card.clone());
    Some(card)
}

pub fn overview(state: &DbState, user_id: Uuid, now: DateTime<Utc>) -> PracticeOverviewDto {
    let mut cards: Vec<&SrsCard> = state.cards.values().filter(|c| c.user_id == user_id).collect();
    cards.sort_by_key(|c| (c.due_at, c.word.clone()));

    let due_now: Vec<SrsCardDto> = cards
        .iter()
        .filter(|c| c.due_at <= now)
        .map(|c| to_dto(c, now))
        .collect();
    let upcoming: Vec<SrsCardDto> = cards
        .iter()
        .filter(|c| c.due_at > now)
        .map(|c| to_dto(c, now))
        .collect();
    let mastered: Vec<SrsCardDto> = cards
        .iter()
        .filter(|c| c.reps >= 3 && c.stability >= 5.0)
        .map(|c| to_dto(c, now))
        .collect();

    let mut mistakes: Vec<MistakeDto> = state
        .mistakes
        .values()
        .filter(|m| m.user_id == user_id && m.reviewed_at.is_none())
        .map(|m| MistakeDto {
            exercise_id: m.exercise_id,
            prompt: m.prompt.clone(),
            correct_answer: m.correct_answer.clone(),
            your_answer: m.your_answer.clone(),
            occurred_at: m.occurred_at,
        })
        .collect();
    mistakes.sort_by(|a, b| b.occurred_at.cmp(&a.occurred_at));

    PracticeOverviewDto {
        due_now,
        upcoming,
        mastered,
        mistakes,
    }
}
