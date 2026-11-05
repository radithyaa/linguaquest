//! Papan peringkat liga mingguan (SRS 9.4).

use chrono::{DateTime, Datelike, Duration, NaiveDate, Utc};
use lq_types::{LeagueEntryDto, LeagueOverviewDto};
use uuid::Uuid;

use crate::db::{DbState, LeagueMemberRow};

pub const TIERS: &[&str] = &[
    "bronze",
    "silver",
    "gold",
    "sapphire",
    "ruby",
    "emerald",
    "amethyst",
    "pearl",
    "obsidian",
    "diamond",
];

pub const PROMOTION_CUTOFF: i32 = 5;
pub const DEMOTION_CUTOFF: i32 = 26;

/// Id musim mingguan ISO-th (mis. `2026-W45`).
pub fn current_season(now: DateTime<Utc>) -> String {
    let iso = now.iso_week();
    format!("{}-W{:02}", iso.year(), iso.week())
}

/// Akhir musim = Minggu 23:59:59 UTC pekan berjalan.
pub fn season_end(now: DateTime<Utc>) -> DateTime<Utc> {
    let weekday = now.weekday().num_days_from_monday() as i64;
    let start_of_week: NaiveDate = now.date_naive() - Duration::days(weekday);
    let sunday_end = start_of_week + Duration::days(6);
    DateTime::<Utc>::from_naive_utc_and_offset(
        sunday_end.and_hms_opt(23, 59, 59).unwrap_or_default(),
        Utc,
    )
}

pub fn next_tier(tier: &str) -> Option<String> {
    let idx = TIERS.iter().position(|t| *t == tier)?;
    TIERS.get(idx + 1).map(|t| t.to_string())
}

pub fn add_weekly_xp(state: &mut DbState, user_id: Uuid, amount: i64) {
    let now = Utc::now();
    let season = current_season(now);
    let group = group_for(state, user_id, &season);
    if let Some(member) = state
        .league
        .iter_mut()
        .find(|m| m.season_id == season && m.group_id == group && m.user_id == user_id)
    {
        member.weekly_xp += amount;
    } else {
        state.league.push(LeagueMemberRow {
            season_id: season,
            group_id: group,
            user_id,
            weekly_xp: amount,
        });
    }
}

/// Grup liga deterministik: pembagian 30 pemain berdasarkan tier.
pub fn group_for(state: &DbState, user_id: Uuid, _season: &str) -> String {
    let tier = state
        .stats
        .get(&user_id)
        .map(|s| s.league_tier.clone())
        .unwrap_or_else(|| "bronze".to_string());
    format!("tier_{}", tier)
}

fn weekly_xp_of(state: &DbState, user_id: Uuid, season: &str) -> i64 {
    state
        .league
        .iter()
        .filter(|m| m.season_id == season && m.user_id == user_id)
        .map(|m| m.weekly_xp)
        .sum()
}

pub fn overview(state: &DbState, user_id: Uuid) -> LeagueOverviewDto {
    let now = Utc::now();
    let season = current_season(now);
    let tier = state
        .stats
        .get(&user_id)
        .map(|s| s.league_tier.clone())
        .unwrap_or_else(|| "bronze".to_string());
    let group = group_for(state, user_id, &season);

    let mut rows: Vec<(Uuid, i64)> = state
        .league
        .iter()
        .filter(|m| m.season_id == season && m.group_id == group)
        .map(|m| (m.user_id, m.weekly_xp))
        .collect();
    // Pastikan pengguna selalu tampil.
    if !rows.iter().any(|(id, _)| *id == user_id) {
        rows.push((user_id, weekly_xp_of(state, user_id, &season)));
    }
    rows.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));
    rows.truncate(30);

    let mut entries = Vec::new();
    let mut current_rank = rows.len() as i32;
    for (index, (member_id, weekly_xp)) in rows.iter().enumerate() {
        let Some(member) = state.users.get(member_id) else { continue };
        let rank = (index + 1) as i32;
        if *member_id == user_id {
            current_rank = rank;
        }
        entries.push(LeagueEntryDto {
            rank,
            user_id: *member_id,
            display_name: member.display_name.clone(),
            username: member.username.clone(),
            avatar_url: member.avatar_url.clone(),
            weekly_xp: *weekly_xp,
            is_current_user: *member_id == user_id,
        });
    }

    LeagueOverviewDto {
        season_id: season,
        tier: tier.clone(),
        next_tier: next_tier(&tier),
        ends_at: season_end(now),
        promotion_cutoff: PROMOTION_CUTOFF,
        demotion_cutoff: DEMOTION_CUTOFF,
        current_user_rank: current_rank,
        entries,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn season_end_is_sunday_2359_utc() {
        let now = DateTime::parse_from_rfc3339("2026-11-05T10:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let end = season_end(now);
        assert_eq!(end.weekday(), chrono::Weekday::Sun);
        assert_eq!(end.format("%H:%M:%S").to_string(), "23:59:59");
    }

    #[test]
    fn tier_progression() {
        assert_eq!(next_tier("bronze"), Some("silver".into()));
        assert_eq!(next_tier("diamond"), None);
    }
}
