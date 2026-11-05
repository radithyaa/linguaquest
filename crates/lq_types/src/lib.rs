//! Shared DTOs, enums, dan kontrak API LinguaQuest.
//!
//! Dipakai bersama oleh:
//! - `lq_api` (server Axum) untuk request/response JSON
//! - `lq_db` untuk baris domain & proyeksi ke DTO
//! - `lq_bridge` untuk tipe lintas bahasa (FFI/WASM)
//!
//! Serde memakai *camelCase* agar Dart dapat `jsonDecode` langsung.

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ---------------------------------------------------------------------------
// Kurikulum / Content
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ExerciseKind {
    MultipleChoice,
    WordBank,
    Typing,
    Listening,
    PairMatching,
    FillInTheBlank,
    Speech,
    Story,
    CharacterWriting,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NodeStatus {
    Locked,
    Current,
    Completed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MatchingPair {
    pub left: String,
    pub right: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Exercise {
    pub id: Uuid,
    /// Relasi ke `lessons.id` (diisi saat dimuat dari penyimpanan).
    #[serde(default)]
    pub lesson_id: Option<Uuid>,
    pub kind: ExerciseKind,
    pub position: i32,
    pub prompt: String,
    pub instruction: Option<String>,
    pub translation: Option<String>,
    pub audio_url: Option<String>,
    pub options: Vec<String>,
    pub correct_answer: String,
    pub acceptable_answers: Vec<String>,
    pub word_bank: Vec<String>,
    pub pairs: Vec<MatchingPair>,
    pub explanation: Option<String>,
}

/// Soal untuk klien: `correct_answer` tidak pernah dikirim agar penilaian
/// tetap dilakukan di server / mesin `lq_core`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExerciseDto {
    pub id: Uuid,
    pub kind: ExerciseKind,
    pub position: i32,
    pub prompt: String,
    pub instruction: Option<String>,
    pub translation: Option<String>,
    pub audio_url: Option<String>,
    pub options: Vec<String>,
    pub word_bank: Vec<String>,
    pub pairs: Vec<MatchingPair>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LessonNodeDto {
    pub id: Uuid,
    pub kind: String,
    pub title: String,
    pub description: String,
    pub position: i32,
    pub lesson_id: Option<Uuid>,
    pub total_exercises: i32,
    pub status: NodeStatus,
    pub is_mastered: bool,
    pub current_position: i32,
    pub exercises: Vec<ExerciseDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GuidebookDto {
    pub summary: String,
    pub grammar_tips: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UnitDto {
    pub id: Uuid,
    pub position: i32,
    pub title: String,
    pub description: String,
    pub theme_color: String,
    pub guidebook: GuidebookDto,
    pub nodes: Vec<LessonNodeDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CourseDto {
    pub id: Uuid,
    pub from_lang: String,
    pub to_lang: String,
    pub title: String,
    pub version: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LessonDetailDto {
    pub lesson_id: Uuid,
    pub node_id: Uuid,
    pub title: String,
    pub exercises: Vec<ExerciseDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CurriculumDto {
    pub course: CourseDto,
    pub units: Vec<UnitDto>,
}

// ---------------------------------------------------------------------------
// Pengguna & Autentikasi
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserDto {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub display_name: String,
    pub avatar_url: Option<String>,
    pub is_guest: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub user: UserDto,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RefreshResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub display_name: String,
    pub username: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GuestRequest {
    pub display_name: Option<String>,
}

/// Migrasi akun tamu (AUTH-04) menjadi akun permanen.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpgradeGuestRequest {
    pub email: String,
    pub password: String,
    pub display_name: String,
    pub username: Option<String>,
}

// ---------------------------------------------------------------------------
// Statistik & Gamifikasi
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserStats {
    pub user_id: Uuid,
    pub total_xp: i64,
    pub level: i32,
    pub streak: i32,
    pub longest_streak: i32,
    /// Format `YYYY-MM-DD`.
    pub last_active_date: Option<String>,
    pub hearts: i32,
    pub hearts_updated_at: DateTime<Utc>,
    pub gems: i32,
    pub freezes_available: i32,
    pub daily_goal_xp: i32,
    pub xp_today: i32,
    /// Detik hingga heart berikutnya pulih (0 jika penuh).
    pub next_heart_seconds: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AchievementDto {
    pub code: String,
    pub title: String,
    pub description: String,
    pub progress: f64,
    pub unlocked: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProfileDto {
    pub user: UserDto,
    pub stats: UserStats,
    pub league_tier: String,
    pub achievements: Vec<AchievementDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateProfileRequest {
    pub display_name: Option<String>,
    pub daily_goal_xp: Option<i32>,
    pub timezone: Option<String>,
}

// ---------------------------------------------------------------------------
// Sesi Pelajaran
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StartSessionRequest {
    pub node_id: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StartSessionResponse {
    pub session_id: Uuid,
    pub lesson_id: Uuid,
    pub node_id: Uuid,
    pub exercises: Vec<ExerciseDto>,
    pub hearts: i32,
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AnswerSubmission {
    pub exercise_id: Uuid,
    pub answer: String,
    #[serde(default)]
    pub duration_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CompleteSessionRequest {
    pub session_id: Option<Uuid>,
    pub client_op_id: Uuid,
    pub node_id: Uuid,
    pub started_at: DateTime<Utc>,
    pub duration_ms: i64,
    pub answers: Vec<AnswerSubmission>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AnswerResultDto {
    pub exercise_id: Uuid,
    pub is_correct: bool,
    pub accepted: bool,
    pub typo_warning: bool,
    pub correct_answer: String,
    pub explanation: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionSummaryDto {
    pub session_id: Uuid,
    pub lesson_id: Uuid,
    pub node_id: Uuid,
    pub total_questions: i32,
    pub correct_count: i32,
    pub accuracy: f64,
    pub max_combo: i32,
    pub xp_earned: i32,
    pub gems_earned: i32,
    pub hearts_lost: i32,
    pub duration_ms: i64,
    pub is_mastered: bool,
    pub streak: i32,
    pub stats: UserStats,
    pub answers: Vec<AnswerResultDto>,
}

/// Sesi yang direkam offline (Drift) lalu disinkronkan saat online (SRS 11.1).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OfflineSessionPayload {
    pub client_op_id: Uuid,
    pub node_id: Uuid,
    pub started_at: DateTime<Utc>,
    pub completed_at: DateTime<Utc>,
    pub duration_ms: i64,
    pub answers: Vec<AnswerSubmission>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncRequest {
    #[serde(default)]
    pub sessions: Vec<OfflineSessionPayload>,
    #[serde(default)]
    pub reviews: Vec<FsrsReviewRequest>,
    #[serde(default)]
    pub purchases: Vec<PurchaseRequest>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RejectedOp {
    pub client_op_id: Uuid,
    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncResponse {
    pub applied_ops: Vec<Uuid>,
    pub rejected_ops: Vec<RejectedOp>,
    pub summaries: Vec<SessionSummaryDto>,
    pub stats: UserStats,
}

// ---------------------------------------------------------------------------
// SRS / FSRS
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum FsrsRating {
    Again = 1,
    Hard = 2,
    Good = 3,
    Easy = 4,
}

impl FsrsRating {
    pub fn as_i32(self) -> i32 {
        self as i32
    }

    pub fn from_i32(value: i32) -> Option<Self> {
        match value {
            1 => Some(Self::Again),
            2 => Some(Self::Hard),
            3 => Some(Self::Good),
            4 => Some(Self::Easy),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrsCard {
    pub id: Uuid,
    pub user_id: Uuid,
    pub word: String,
    pub translation: String,
    pub stability: f32,
    pub difficulty: f32,
    pub due_at: DateTime<Utc>,
    pub last_review: Option<DateTime<Utc>>,
    pub reps: i32,
    pub lapses: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrsCardDto {
    pub id: Uuid,
    pub word: String,
    pub translation: String,
    pub stability: f32,
    pub difficulty: f32,
    pub due_at: DateTime<Utc>,
    pub reps: i32,
    pub lapses: i32,
    pub retrievability: f32,
    pub interval_days: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MistakeDto {
    pub exercise_id: Uuid,
    pub prompt: String,
    pub correct_answer: String,
    pub your_answer: String,
    pub occurred_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PracticeOverviewDto {
    pub due_now: Vec<SrsCardDto>,
    pub upcoming: Vec<SrsCardDto>,
    pub mastered: Vec<SrsCardDto>,
    pub mistakes: Vec<MistakeDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FsrsReviewRequest {
    pub card_id: Uuid,
    pub rating: i32,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub client_op_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FsrsReviewResponse {
    pub card: SrsCardDto,
}

// ---------------------------------------------------------------------------
// Toko & Transaksi
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ShopItemDto {
    pub sku: String,
    pub title: String,
    pub description: String,
    pub price_gems: i32,
    pub icon: String,
    pub color: String,
    pub available: bool,
    pub owned: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PurchaseRequest {
    pub sku: String,
    pub client_op_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PurchaseResponse {
    pub success: bool,
    pub stats: UserStats,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WalletEntryDto {
    pub id: i64,
    pub delta: i32,
    pub reason: String,
    pub created_at: DateTime<Utc>,
}

// ---------------------------------------------------------------------------
// Quest
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QuestDto {
    pub code: String,
    pub title: String,
    pub description: String,
    pub icon: String,
    pub color: String,
    pub progress: i32,
    pub target: i32,
    pub reward_gems: i32,
    pub completed: bool,
    pub claimed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MonthlyQuestDto {
    pub title: String,
    pub description: String,
    pub progress: i32,
    pub target: i32,
    pub reward_title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QuestOverviewDto {
    pub local_date: NaiveDate,
    pub daily: Vec<QuestDto>,
    pub monthly: MonthlyQuestDto,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ClaimQuestResponse {
    pub gems_awarded: i32,
    pub stats: UserStats,
}

// ---------------------------------------------------------------------------
// Liga
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LeagueEntryDto {
    pub rank: i32,
    pub user_id: Uuid,
    pub display_name: String,
    pub username: String,
    pub avatar_url: Option<String>,
    pub weekly_xp: i64,
    pub is_current_user: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LeagueOverviewDto {
    pub season_id: String,
    pub tier: String,
    pub next_tier: Option<String>,
    pub ends_at: DateTime<Utc>,
    pub promotion_cutoff: i32,
    pub demotion_cutoff: i32,
    pub current_user_rank: i32,
    pub entries: Vec<LeagueEntryDto>,
}

// ---------------------------------------------------------------------------
// Admin CMS
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateUnitRequest {
    pub course_id: Option<Uuid>,
    pub title: String,
    pub description: String,
    pub summary: String,
    pub grammar_tips: Vec<String>,
    pub theme_color: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateNodeRequest {
    pub unit_id: Uuid,
    pub title: String,
    pub description: String,
    pub kind: Option<String>,
    pub exercises: Vec<NewExerciseRequest>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NewExerciseRequest {
    pub kind: ExerciseKind,
    pub prompt: String,
    pub instruction: Option<String>,
    pub correct_answer: String,
    #[serde(default)]
    pub acceptable_answers: Vec<String>,
    #[serde(default)]
    pub options: Vec<String>,
    #[serde(default)]
    pub word_bank: Vec<String>,
    #[serde(default)]
    pub pairs: Vec<MatchingPair>,
    pub explanation: Option<String>,
}

// ---------------------------------------------------------------------------
// Health / Utilitas
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HealthDto {
    pub status: String,
    pub version: String,
    pub database: String,
    pub redis: String,
    pub uptime_seconds: i64,
    pub server_time: DateTime<Utc>,
}

/// Format RFC 9457 Problem Details (SRS 7.3).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProblemDetails {
    #[serde(rename = "type")]
    pub problem_type: String,
    pub title: String,
    pub status: u16,
    pub detail: String,
    pub code: String,
    pub timestamp: DateTime<Utc>,
}

impl ProblemDetails {
    pub fn new(status: u16, code: &str, title: &str, detail: impl Into<String>) -> Self {
        Self {
            problem_type: format!("https://api.linguaquest.app/errors/{}", slug(code)),
            title: title.to_string(),
            status,
            detail: detail.into(),
            code: code.to_string(),
            timestamp: Utc::now(),
        }
    }
}

fn slug(code: &str) -> String {
    code.to_ascii_lowercase().replace('_', "-")
}

// ---------------------------------------------------------------------------
// Evaluasi jawaban (lintas FFI)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum EvaluationStatus {
    Correct,
    TypoWarning,
    Incorrect,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AnswerEvaluation {
    pub status: EvaluationStatus,
    pub canonical_answer: String,
    pub distance: i32,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn problem_details_serializes_rfc9457() {
        let p = ProblemDetails::new(403, "HEARTS_EXHAUSTED", "Hearts Depleted", "kosong");
        let json = serde_json::to_string(&p).unwrap();
        assert!(json.contains("\"type\":\"https://api.linguaquest.app/errors/hearts-exhausted\""));
        assert!(json.contains("\"code\":\"HEARTS_EXHAUSTED\""));
    }

    #[test]
    fn exercise_dto_is_camel_case() {
        let dto = ExerciseDto {
            id: Uuid::nil(),
            kind: ExerciseKind::MultipleChoice,
            position: 1,
            prompt: "Hello".into(),
            instruction: None,
            translation: None,
            audio_url: None,
            options: vec![],
            word_bank: vec![],
            pairs: vec![],
        };
        let json = serde_json::to_string(&dto).unwrap();
        assert!(json.contains("\"audioUrl\":null"));
        assert!(json.contains("\"wordBank\":[]"));
        assert!(json.contains("\"multiple_choice\""));
    }
}
