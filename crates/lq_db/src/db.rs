//! Model data & backend penyimpanan LinguaQuest.
//!
//! Desain:
//! - `DbState` adalah representasi lengkap domain di memori (dipakai engine pelajaran).
//! - `Backend::Pg` menyimpan state tersebut di **PostgreSQL 16** pada setiap mutation
//!   (`save_*`), sehingga data tetap persisten dan query SQL tetap menjadi *source of truth*.
//! - `Backend::Memory` adalah mode demo otomatis ketika PostgreSQL tidak tersedia.
//!
//! Dengan pola ini, seluruh aturan bisnis hanya ditulis satu kali (tidak ada
//! duplikasi SQL vs Rust), sementara PostgreSQL tetap menyimpan data nyata.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, RwLock};

use chrono::{DateTime, NaiveDate, Utc};
use lq_types::{Exercise, SrsCard};
use uuid::Uuid;

use crate::pool::DbPool;

// ---------------------------------------------------------------------------
// Baris domain
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct UserRow {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub password_hash: Option<String>,
    pub display_name: String,
    pub avatar_url: Option<String>,
    pub is_guest: bool,
    pub role: String,
    pub timezone: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone)]
pub struct StatsRow {
    pub user_id: Uuid,
    pub total_xp: i64,
    pub level: i32,
    pub streak: i32,
    pub longest_streak: i32,
    pub last_active_date: Option<NaiveDate>,
    pub hearts: i32,
    pub hearts_updated_at: DateTime<Utc>,
    pub gems: i32,
    pub freezes_available: i32,
    pub daily_goal_xp: i32,
    pub league_tier: String,
}

impl StatsRow {
    pub fn new(user_id: Uuid) -> Self {
        Self {
            user_id,
            total_xp: 0,
            level: 1,
            streak: 0,
            longest_streak: 0,
            last_active_date: None,
            hearts: lq_core::MAX_HEARTS,
            hearts_updated_at: Utc::now(),
            gems: 0,
            freezes_available: 0,
            daily_goal_xp: 20,
            league_tier: "bronze".to_string(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct CourseRow {
    pub id: Uuid,
    pub from_lang: String,
    pub to_lang: String,
    pub title: String,
    pub version: i32,
}

#[derive(Debug, Clone)]
pub struct UnitRow {
    pub id: Uuid,
    pub course_id: Uuid,
    pub position: i32,
    pub title: String,
    pub description: String,
    pub theme_color: String,
    pub guidebook: serde_json::Value,
}

#[derive(Debug, Clone)]
pub struct NodeRow {
    pub id: Uuid,
    pub unit_id: Uuid,
    pub position: i32,
    pub kind: String,
    pub title: String,
    pub description: String,
}

#[derive(Debug, Clone)]
pub struct LessonRow {
    pub id: Uuid,
    pub node_id: Uuid,
    pub position: i32,
}

#[derive(Debug, Clone, Default)]
pub struct ProgressRow {
    pub status: String,
    pub best_accuracy: f64,
    pub mastered: bool,
    pub attempts: i32,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone)]
pub struct AttemptRow {
    pub id: Uuid,
    pub user_id: Uuid,
    pub lesson_id: Uuid,
    pub node_id: Uuid,
    pub started_at: DateTime<Utc>,
    pub completed_at: DateTime<Utc>,
    pub accuracy: f64,
    pub correct_count: i32,
    pub total_questions: i32,
    pub max_combo: i32,
    pub xp_awarded: i32,
    pub hearts_lost: i32,
    pub duration_ms: i64,
    pub client_op_id: Uuid,
    pub answers_json: serde_json::Value,
}

#[derive(Debug, Clone)]
pub struct MistakeRow {
    pub user_id: Uuid,
    pub exercise_id: Uuid,
    pub prompt: String,
    pub correct_answer: String,
    pub your_answer: String,
    pub occurred_at: DateTime<Utc>,
    pub reviewed_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone)]
pub struct WalletRow {
    pub id: i64,
    pub user_id: Uuid,
    pub delta: i32,
    pub reason: String,
    pub ref_id: Option<Uuid>,
    pub client_op_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone)]
pub struct QuestProgressRow {
    pub user_id: Uuid,
    pub local_date: NaiveDate,
    pub quest_code: String,
    pub progress: i32,
    pub claimed: bool,
}

#[derive(Debug, Clone)]
pub struct LeagueMemberRow {
    pub season_id: String,
    pub group_id: String,
    pub user_id: Uuid,
    pub weekly_xp: i64,
}

/// Sesi pelajaran aktif (nonce yang diterbitkan saat `POST /sessions/start`).
#[derive(Debug, Clone)]
pub struct SessionRow {
    pub id: Uuid,
    pub user_id: Uuid,
    pub node_id: Uuid,
    pub lesson_id: Uuid,
    pub started_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub exercise_ids: Vec<Uuid>,
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

#[derive(Debug, Default)]
pub struct DbState {
    pub users: HashMap<Uuid, UserRow>,
    pub stats: HashMap<Uuid, StatsRow>,
    pub sessions: HashMap<Uuid, SessionRow>,
    pub courses: Vec<CourseRow>,
    pub units: Vec<UnitRow>,
    pub nodes: Vec<NodeRow>,
    pub lessons: Vec<LessonRow>,
    pub exercises: HashMap<Uuid, Vec<Exercise>>,
    pub progress: HashMap<(Uuid, Uuid), ProgressRow>,
    pub attempts: Vec<AttemptRow>,
    pub mistakes: HashMap<(Uuid, Uuid), MistakeRow>,
    pub cards: HashMap<(Uuid, String), SrsCard>,
    pub wallet: Vec<WalletRow>,
    pub quests: HashMap<(Uuid, NaiveDate, String), QuestProgressRow>,
    pub league: Vec<LeagueMemberRow>,
    pub applied_ops: HashSet<Uuid>,
    pub wallet_seq: i64,
    pub refresh_tokens: HashMap<String, RefreshTokenRow>,
}

/// Refresh token tersimpan (hanya hash SHA-256 yang disimpan).
#[derive(Debug, Clone)]
pub struct RefreshTokenRow {
    pub user_id: Uuid,
    pub expires_at: DateTime<Utc>,
    pub revoked: bool,
}

impl DbState {
    pub fn find_user_by_email(&self, email: &str) -> Option<&UserRow> {
        self.users.values().find(|u| u.email.eq_ignore_ascii_case(email))
    }

    pub fn find_user_by_username(&self, username: &str) -> Option<&UserRow> {
        self.users
            .values()
            .find(|u| u.username.eq_ignore_ascii_case(username))
    }

    pub fn node(&self, node_id: Uuid) -> Option<&NodeRow> {
        self.nodes.iter().find(|n| n.id == node_id)
    }

    pub fn unit(&self, unit_id: Uuid) -> Option<&UnitRow> {
        self.units.iter().find(|u| u.id == unit_id)
    }

    pub fn course(&self, course_id: Uuid) -> Option<&CourseRow> {
        self.courses.iter().find(|c| c.id == course_id)
    }

    pub fn unit_of_node(&self, node_id: Uuid) -> Option<&UnitRow> {
        let node = self.node(node_id)?;
        self.unit(node.unit_id)
    }

    pub fn course_of_node(&self, node_id: Uuid) -> Option<&CourseRow> {
        let unit = self.unit_of_node(node_id)?;
        self.course(unit.course_id)
    }

    pub fn lesson_of_node(&self, node_id: Uuid) -> Option<&LessonRow> {
        self.lessons.iter().find(|l| l.node_id == node_id)
    }

    pub fn lesson_exercises(&self, lesson_id: Uuid) -> Vec<Exercise> {
        let mut list = self.exercises.get(&lesson_id).cloned().unwrap_or_default();
        list.sort_by_key(|e| e.position);
        list
    }

    pub fn node_exercises(&self, node_id: Uuid) -> Vec<Exercise> {
        self.lesson_of_node(node_id)
            .map(|l| self.lesson_exercises(l.id))
            .unwrap_or_default()
    }

    pub fn units_of_course(&self, course_id: Uuid) -> Vec<&UnitRow> {
        let mut list: Vec<&UnitRow> = self.units.iter().filter(|u| u.course_id == course_id).collect();
        list.sort_by_key(|u| u.position);
        list
    }

    pub fn nodes_of_unit(&self, unit_id: Uuid) -> Vec<&NodeRow> {
        let mut list: Vec<&NodeRow> = self.nodes.iter().filter(|n| n.unit_id == unit_id).collect();
        list.sort_by_key(|n| n.position);
        list
    }

    /// Node dengan posisi paling jauh yang sudah terbuka untuk pengguna.
    /// Unit terbuka jika seluruh node unit sebelumnya selesai.
    pub fn unlocked_position(&self, user_id: Uuid, node_id: Uuid) -> i32 {
        let Some(node) = self.node(node_id) else { return 1 };
        let Some(unit) = self.unit(node.unit_id) else { return 1 };

        for prior in self.units_of_course(unit.course_id) {
            if prior.position >= unit.position {
                break;
            }
            let all_done = self
                .nodes_of_unit(prior.id)
                .iter()
                .all(|n| self.is_completed(user_id, n.id));
            if !all_done {
                return 0;
            }
        }

        let mut unlocked = 1;
        for candidate in self.nodes_of_unit(unit.id) {
            unlocked = candidate.position;
            if !self.is_completed(user_id, candidate.id) {
                break;
            }
        }
        unlocked.max(1)
    }

    pub fn is_completed(&self, user_id: Uuid, node_id: Uuid) -> bool {
        self.progress
            .get(&(user_id, node_id))
            .map(|p| p.status == "completed")
            .unwrap_or(false)
    }

    pub fn xp_on(&self, user_id: Uuid, date: NaiveDate) -> i32 {
        self.attempts
            .iter()
            .filter(|a| a.user_id == user_id && a.completed_at.date_naive() == date)
            .map(|a| a.xp_awarded)
            .sum()
    }

    pub fn wallet_balance(&self, user_id: Uuid) -> i32 {
        self.wallet
            .iter()
            .filter(|w| w.user_id == user_id)
            .map(|w| w.delta)
            .sum()
    }

    pub fn level_for_xp(total_xp: i64) -> i32 {
        let mut level = 1;
        let mut threshold: i64 = 100;
        let mut remaining = total_xp;
        while remaining >= threshold {
            remaining -= threshold;
            level += 1;
            threshold += 50;
        }
        level
    }
}

// ---------------------------------------------------------------------------
// Backend
// ---------------------------------------------------------------------------

#[derive(Clone)]
pub struct Storage {
    pub state: Arc<RwLock<DbState>>,
    pub pg: Option<DbPool>,
    pub persistent: bool,
}

impl Storage {
    pub fn memory() -> Self {
        Self::memory_with_state(DbState::default())
    }

    pub async fn postgres(pool: DbPool, state: DbState) -> Self {
        Self {
            state: Arc::new(RwLock::new(state)),
            pg: Some(pool),
            persistent: true,
        }
    }

    pub fn memory_with_state(state: DbState) -> Self {
        Self {
            state: Arc::new(RwLock::new(state)),
            pg: None,
            persistent: false,
        }
    }

    pub fn read<T>(&self, f: impl FnOnce(&DbState) -> T) -> T {
        let guard = self.state.read().unwrap_or_else(|poisoned| poisoned.into_inner());
        f(&guard)
    }

    pub fn write<T>(&self, f: impl FnOnce(&mut DbState) -> T) -> T {
        let mut guard = self.state.write().unwrap_or_else(|poisoned| poisoned.into_inner());
        f(&mut guard)
    }

    /// Sinkronkan seluruh state ke PostgreSQL (dipanggil setelah mutation).
    pub async fn persist(&self) -> anyhow::Result<()> {
        if let Some(pool) = &self.pg {
            crate::persist::persist_all(pool, &self.state).await?;
        }
        Ok(())
    }
}
