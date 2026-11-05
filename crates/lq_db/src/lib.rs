//! Lapisan basis data LinguaQuest (PostgreSQL 16 + backend in-memory untuk mode demo).

pub mod curriculum;
pub mod db;
pub mod gamification;
pub mod league;
pub mod learning;
pub mod migrate;
pub mod persist;
pub mod pool;
pub mod quests;
pub mod seed;
pub mod srs;
pub mod users;

pub use db::{DbState, Storage};
pub use pool::{connect, DbConfig, DbPool};

use anyhow::Context;

pub const DDL_SCHEMA: &str = include_str!("../migrations/0002_schema.sql");

/// Siapkan penyimpanan: PostgreSQL bila `DATABASE_URL` dapat dihubungi,
/// jika tidak fallback ke backend in-memory yang sudah di-seed.
pub async fn init_storage(cfg: &DbConfig) -> Storage {
    match try_postgres(cfg).await {
        Ok(storage) => {
            tracing::info!("database: PostgreSQL terhubung (persisten)");
            storage
        }
        Err(error) => {
            tracing::warn!(
                error = %error,
                "database: PostgreSQL tidak tersedia — memakai penyimpanan in-memory (data hilang saat server restart)"
            );
            fresh_memory_storage()
        }
    }
}

pub fn fresh_memory_storage() -> Storage {
    let mut state = DbState::default();
    seed::seed_curriculum(&mut state);
    seed_demo_users(&mut state);
    Storage::memory_with_state(state)
}

async fn try_postgres(cfg: &DbConfig) -> anyhow::Result<Storage> {
    let pool = connect(cfg).await.context("koneksi PostgreSQL gagal")?;
    migrate::run_migrations(&pool).await?;
    let state = migrate::load_state(&pool).await?;
    Ok(Storage::postgres(pool, state).await)
}

/// Akun demo (kredensial sama dengan `migrations/0004_seed_demo_user.sql`).
/// Hash dihitung dengan Argon2id saat runtime oleh crate `argon2` milik server,
/// sehingga tidak ada hash placeholder yang perlu di-hardcode.
fn seed_demo_users(state: &mut DbState) {
    let demo_id = uuid::Uuid::parse_str(seed::DEMO_USER_ID).expect("uuid demo");
    if state.users.contains_key(&demo_id) {
        return;
    }
    let user = db::UserRow {
        id: demo_id,
        username: "demo".into(),
        email: "demo@linguaquest.app".into(),
        password_hash: None,
        display_name: "Pelajar Hebat".into(),
        avatar_url: None,
        is_guest: false,
        role: "user".into(),
        timezone: "Asia/Jakarta".into(),
        created_at: chrono::Utc::now(),
    };
    state.users.insert(demo_id, user);

    let mut stats = db::StatsRow::new(demo_id);
    stats.total_xp = 320;
    stats.level = DbState::level_for_xp(320);
    stats.streak = 4;
    stats.longest_streak = 6;
    stats.gems = 450;
    stats.freezes_available = 1;
    stats.league_tier = "emerald".into();
    let hearts_updated_at = stats.hearts_updated_at;
    state.stats.insert(demo_id, stats);

    state.wallet.push(db::WalletRow {
        id: 1,
        user_id: demo_id,
        delta: 450,
        reason: "seed:starting_gems".into(),
        ref_id: None,
        client_op_id: None,
        created_at: hearts_updated_at,
    });
    state.wallet_seq = 1;
}
