use chrono::{DateTime, Duration, Utc};
use lq_types::UserStats;

pub const BASE_XP: i32 = 10;
pub const MAX_HEARTS: i32 = 5;
pub const HEART_REGEN_HOURS: i64 = 4;

/// Formula SRS Bab 9.1: XP_total = XP_base + XP_accuracy_bonus + XP_combo_bonus
pub fn calculate_xp(accuracy: f32, max_combo: i32) -> i32 {
    let accuracy_bonus = if accuracy >= 1.0 {
        5
    } else if accuracy >= 0.90 {
        3
    } else {
        0
    };

    let combo_bonus = ((max_combo / 5) * 2).min(6);

    BASE_XP + accuracy_bonus + combo_bonus
}

/// Calculate heart regeneration based on elapsed time since last update (1 heart every 4 hours)
pub fn regenerate_hearts(current_hearts: i32, last_update: DateTime<Utc>, now: DateTime<Utc>) -> (i32, DateTime<Utc>) {
    if current_hearts >= MAX_HEARTS {
        return (MAX_HEARTS, now);
    }

    let elapsed = now.signed_duration_since(last_update);
    let hours_passed = elapsed.num_hours();
    if hours_passed <= 0 {
        return (current_hearts, last_update);
    }

    let hearts_to_add = (hours_passed / HEART_REGEN_HOURS) as i32;
    if hearts_to_add <= 0 {
        return (current_hearts, last_update);
    }

    let updated_hearts = (current_hearts + hearts_to_add).min(MAX_HEARTS);
    let remainder_hours = hours_passed % HEART_REGEN_HOURS;
    let new_update_time = now - Duration::hours(remainder_hours);

    (updated_hearts, new_update_time)
}

/// Check and evaluate streak update when user completes a session on `today_date_str`
pub fn update_streak(
    stats: &mut UserStats,
    today_date_str: &str,
    daily_xp_today: i32,
) {
    if daily_xp_today < stats.daily_goal_xp {
        return;
    }

    match &stats.last_active_date {
        Some(last_date) if last_date == today_date_str => {
            // Already counted today
        }
        Some(last_date) => {
            // Check if last_date is yesterday
            // Simple string format YYYY-MM-DD
            if is_yesterday(last_date, today_date_str) {
                stats.streak += 1;
            } else {
                // Streak broken or freeze used
                if stats.freezes_available > 0 {
                    stats.freezes_available -= 1;
                    // Streak preserved
                } else {
                    stats.streak = 1;
                }
            }
            stats.last_active_date = Some(today_date_str.to_string());
        }
        None => {
            stats.streak = 1;
            stats.last_active_date = Some(today_date_str.to_string());
        }
    }

    if stats.streak > stats.longest_streak {
        stats.longest_streak = stats.streak;
    }
}

fn is_yesterday(last: &str, today: &str) -> bool {
    use chrono::NaiveDate;
    if let (Ok(d1), Ok(d2)) = (NaiveDate::parse_from_str(last, "%Y-%m-%d"), NaiveDate::parse_from_str(today, "%Y-%m-%d")) {
        (d2 - d1).num_days() == 1
    } else {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_xp_calculation() {
        assert_eq!(calculate_xp(1.0, 15), 10 + 5 + 6); // 21 XP
        assert_eq!(calculate_xp(0.95, 8), 10 + 3 + 2); // 15 XP
        assert_eq!(calculate_xp(0.80, 2), 10 + 0 + 0); // 10 XP
    }

    #[test]
    fn test_heart_regeneration() {
        let past = Utc::now() - Duration::hours(9);
        let now = Utc::now();
        let (hearts, _) = regenerate_hearts(2, past, now);
        assert_eq!(hearts, 4); // 9 hours = 2 hearts added (4h * 2 = 8h)
    }

    #[test]
    fn test_streak_continuation() {
        let mut stats = UserStats {
            user_id: Uuid::new_v4(),
            total_xp: 100,
            level: 2,
            streak: 3,
            longest_streak: 3,
            last_active_date: Some("2026-11-04".to_string()),
            hearts: 5,
            hearts_updated_at: Utc::now(),
            gems: 50,
            freezes_available: 1,
            daily_goal_xp: 20,
            xp_today: 25,
            next_heart_seconds: 0,
        };

        update_streak(&mut stats, "2026-11-05", 25);
        assert_eq!(stats.streak, 4);
        assert_eq!(stats.longest_streak, 4);
    }
}
