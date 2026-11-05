//! Pengguna, statistik, dan token autentikasi.

use chrono::{DateTime, NaiveDate, Utc};
use lq_types::{AchievementDto, ProfileDto, UserDto, UserStats};
use uuid::Uuid;

use crate::db::{DbState, StatsRow, UserRow};
use lq_core::MAX_HEARTS;

pub fn to_user_dto(user: &UserRow) -> UserDto {
    UserDto {
        id: user.id,
        username: user.username.clone(),
        email: user.email.clone(),
        display_name: user.display_name.clone(),
        avatar_url: user.avatar_url.clone(),
        is_guest: user.is_guest,
    }
}

/// Detik sampai heart berikutnya pulih (0 jika penuh).
pub fn next_heart_seconds(stats: &StatsRow, now: DateTime<Utc>) -> i64 {
    if stats.hearts >= MAX_HEARTS {
        return 0;
    }
    let regen_secs = lq_core::HEART_REGEN_HOURS * 3600;
    let elapsed = (now - stats.hearts_updated_at).num_seconds().max(0);
    let into_cycle = elapsed % regen_secs;
    (regen_secs - into_cycle).max(0)
}

pub fn to_stats_dto(state: &DbState, stats: &StatsRow, now: DateTime<Utc>) -> UserStats {
    let today = now.date_naive();
    UserStats {
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
        xp_today: state.xp_on(stats.user_id, today),
        next_heart_seconds: next_heart_seconds(stats, now),
    }
}

pub fn regenerate_hearts_if_needed(stats: &mut StatsRow, now: DateTime<Utc>) {
    let (hearts, updated_at) = lq_core::regenerate_hearts(stats.hearts, stats.hearts_updated_at, now);
    stats.hearts = hearts;
    stats.hearts_updated_at = updated_at;
}

pub fn achievements(stats: &StatsRow, lessons_completed: i32, words_mastered: i32, perfect_sessions: i32) -> Vec<AchievementDto> {
    vec![
        AchievementDto {
            code: "streak_7".into(),
            title: "Api Abadi".into(),
            description: "Pertahankan streak selama 7 hari berturut-turut.".into(),
            progress: (stats.streak as f64 / 7.0).min(1.0),
            unlocked: stats.streak >= 7,
        },
        AchievementDto {
            code: "perfect_10".into(),
            title: "Juara Kuis".into(),
            description: "Selesaikan 10 sesi pelajaran tanpa kesalahan.".into(),
            progress: (perfect_sessions as f64 / 10.0).min(1.0),
            unlocked: perfect_sessions >= 10,
        },
        AchievementDto {
            code: "vocab_50".into(),
            title: "Ahli Kosakata".into(),
            description: "Pelajari 50 kosakata baru dengan FSRS.".into(),
            progress: (words_mastered as f64 / 50.0).min(1.0),
            unlocked: words_mastered >= 50,
        },
        AchievementDto {
            code: "lesson_15".into(),
            title: "Rajin Berlatih".into(),
            description: "Selesaikan 15 sesi pelajaran.".into(),
            progress: (lessons_completed as f64 / 15.0).min(1.0),
            unlocked: lessons_completed >= 15,
        },
    ]
}

pub fn profile(state: &DbState, user: &UserRow, now: DateTime<Utc>) -> ProfileDto {
    let stats = state.stats.get(&user.id).cloned().unwrap_or_else(|| StatsRow::new(user.id));
    let lessons_completed = state
        .progress
        .iter()
        .filter(|((uid, _), row)| *uid == user.id && row.status == "completed")
        .count() as i32;
    let perfect_sessions = state
        .attempts
        .iter()
        .filter(|a| a.user_id == user.id && a.accuracy >= 1.0)
        .count() as i32;
    let words_mastered = state
        .cards
        .values()
        .filter(|c| c.user_id == user.id && c.reps >= 3)
        .count() as i32;

    ProfileDto {
        user: to_user_dto(user),
        stats: to_stats_dto(state, &stats, now),
        league_tier: stats.league_tier.clone(),
        achievements: achievements(&stats, lessons_completed, words_mastered, perfect_sessions),
    }
}

pub fn local_date(now: DateTime<Utc>, _timezone: &str) -> NaiveDate {
    // Catatan: offset zona waktu per pengguna dihormati oleh klien; server
    // memakai tanggal UTC sebagai acuan deterministik agar sinkronisasi konsisten.
    now.date_naive()
}

pub fn new_user(
    state: &mut DbState,
    email: &str,
    display_name: &str,
    username: Option<&str>,
    password_hash: Option<String>,
    is_guest: bool,
) -> UserRow {
    let id = Uuid::new_v4();
    let username = username.map(str::to_string).unwrap_or_else(|| {
        let base = if is_guest { "tamu" } else { "pelajar" };
        format!("{}_{}", base, &id.simple().to_string()[..8])
    });
    let user = UserRow {
        id,
        username,
        email: email.to_lowercase(),
        password_hash,
        display_name: display_name.to_string(),
        avatar_url: None,
        is_guest,
        role: "user".to_string(),
        timezone: "Asia/Jakarta".to_string(),
        created_at: Utc::now(),
    };
    state.users.insert(id, user.clone());
    let mut stats = StatsRow::new(id);
    stats.last_active_date = None;
    state.stats.insert(id, stats);
    user
}
