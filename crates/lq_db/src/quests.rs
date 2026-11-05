//! Quest harian & lencana bulanan (SRS GAM-06).

use chrono::{Datelike, NaiveDate, Utc};
use lq_types::{MonthlyQuestDto, QuestDto, QuestOverviewDto};
use uuid::Uuid;

use crate::db::{DbState, QuestProgressRow};

pub struct QuestDef {
    pub code: &'static str,
    pub title: &'static str,
    pub description: &'static str,
    pub icon: &'static str,
    pub color: &'static str,
    pub target: i32,
    pub reward_gems: i32,
}

pub const DAILY_QUESTS: &[QuestDef] = &[
    QuestDef {
        code: "xp_30",
        title: "Dapatkan 30 XP",
        description: "Kumpulkan XP dari sesi pelajaran hari ini.",
        icon: "bolt",
        color: "#FFC800",
        target: 30,
        reward_gems: 10,
    },
    QuestDef {
        code: "lessons_2",
        title: "Selesaikan 2 Sesi Pelajaran",
        description: "Tuntaskan dua sesi apapun hari ini.",
        icon: "check_circle",
        color: "#58CC02",
        target: 2,
        reward_gems: 15,
    },
    QuestDef {
        code: "accuracy_90",
        title: "Raih Akurasi 90%+ dalam 1 Sesi",
        description: "Jawab hampir semua soal dengan benar.",
        icon: "track_changes",
        color: "#1CB0F6",
        target: 1,
        reward_gems: 20,
    },
];

pub const MONTHLY_TARGET: i32 = 20;

fn entry<'a>(state: &'a DbState, user_id: Uuid, date: NaiveDate, code: &str) -> Option<&'a QuestProgressRow> {
    state.quests.get(&(user_id, date, code.to_string()))
}

pub fn record_session(
    state: &mut DbState,
    user_id: Uuid,
    local_date: NaiveDate,
    accuracy: f64,
) {
    let mut bump = |code: &str, amount: i32| {
        let row = state
            .quests
            .entry((user_id, local_date, code.to_string()))
            .or_insert_with(|| QuestProgressRow {
                user_id,
                local_date,
                quest_code: code.to_string(),
                progress: 0,
                claimed: false,
            });
        row.progress += amount;
    };

    // "xp_30" tidak dinaikkan di sini: progresnya dihitung ulang dari XP hari ini.
    bump("lessons_2", 1);
    if accuracy >= 0.9 {
        bump("accuracy_90", 1);
    }
}

pub fn overview(state: &DbState, user_id: Uuid) -> QuestOverviewDto {
    let now = Utc::now();
    let local_date = now.date_naive();
    let xp_today = state.xp_on(user_id, local_date);

    let daily: Vec<QuestDto> = DAILY_QUESTS
        .iter()
        .map(|def| {
            let (progress, claimed) = match def.code {
                "xp_30" => (xp_today, false),
                code => entry(state, user_id, local_date, code)
                    .map(|row| (row.progress, row.claimed))
                    .unwrap_or((0, false)),
            };
            let progress = progress.min(def.target);
            QuestDto {
                code: def.code.to_string(),
                title: def.title.to_string(),
                description: def.description.to_string(),
                icon: def.icon.to_string(),
                color: def.color.to_string(),
                progress,
                target: def.target,
                reward_gems: def.reward_gems,
                completed: progress >= def.target,
                claimed,
            }
        })
        .collect();

    let month = (now.year(), now.month());
    let completed_days = state
        .quests
        .iter()
        .filter(|((uid, date, code), row)| {
            *uid == user_id
                && code == "lessons_2"
                && row.progress >= 2
                && date.year() == month.0
                && date.month() == month.1
        })
        .count() as i32;

    let month_name = match now.month() {
        1 => "Januari",
        2 => "Februari",
        3 => "Maret",
        4 => "April",
        5 => "Mei",
        6 => "Juni",
        7 => "Juli",
        8 => "Agustus",
        9 => "September",
        10 => "Oktober",
        11 => "November",
        _ => "Desember",
    };

    QuestOverviewDto {
        local_date,
        daily,
        monthly: MonthlyQuestDto {
            title: format!("Tantangan Lencana {month_name}"),
            description: format!("Selesaikan {MONTHLY_TARGET} misi harian bulan ini."),
            progress: completed_days.min(MONTHLY_TARGET),
            target: MONTHLY_TARGET,
            reward_title: format!("Lencana {month_name}"),
        },
    }
}

pub enum ClaimError {
    NotFound,
    NotCompleted,
    AlreadyClaimed,
}

pub fn claim(state: &mut DbState, user_id: Uuid, code: &str) -> Result<i32, ClaimError> {
    let def = DAILY_QUESTS.iter().find(|q| q.code == code).ok_or(ClaimError::NotFound)?;
    let local_date = Utc::now().date_naive();
    let xp_today = state.xp_on(user_id, local_date);

    let progress = match code {
        "xp_30" => xp_today,
        other => entry(state, user_id, local_date, other).map(|r| r.progress).unwrap_or(0),
    };
    if progress < def.target {
        return Err(ClaimError::NotCompleted);
    }

    let row = state
        .quests
        .entry((user_id, local_date, code.to_string()))
        .or_insert_with(|| QuestProgressRow {
            user_id,
            local_date,
            quest_code: code.to_string(),
            progress,
            claimed: false,
        });
    if row.claimed {
        return Err(ClaimError::AlreadyClaimed);
    }
    row.claimed = true;

    if let Some(mut stats) = state.stats.get(&user_id).cloned() {
        stats.gems += def.reward_gems;
        state.stats.insert(user_id, stats);
    }
    let ledger_id = state.wallet.iter().map(|w| w.id).max().unwrap_or(0) + 1;
    state.wallet.push(crate::db::WalletRow {
        id: ledger_id,
        user_id,
        delta: def.reward_gems,
        reason: format!("quest:{}", code),
        ref_id: None,
        client_op_id: None,
        created_at: Utc::now(),
    });

    Ok(def.reward_gems)
}
