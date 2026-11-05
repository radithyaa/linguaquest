//! LinguaQuest API Gateway — Axum modular monolith (SRS Bab 7).
//!
//! Jalankan: `cargo run -p lq_api`
//! Env: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `PORT`, `LQ_DEMO_DATA`.

mod auth;
mod error;
mod router;
mod routes;
mod state;

use std::sync::Arc;
use std::time::Duration;

use lq_db::{DbConfig, Storage};
use state::{AppState, RedisHandle};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = dotenvy::dotenv();

    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "lq_api=info,tower_http=warn".into()),
        )
        .init();

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(8090);
    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".into());

    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| {
        tracing::warn!("JWT_SECRET tidak diset — memakai nilai development (jangan dipakai di produksi)");
        "linguaquest-dev-secret-change-me".to_string()
    });

    let db_config = DbConfig::from_env();
    let mut storage = lq_db::init_storage(&db_config).await;
    if storage.persistent {
        seed_demo_account(&storage).await;
        if std::env::var("LQ_DEMO_DATA").as_deref() == Ok("1") {
            seed_leaderboard(&storage);
            let _ = storage.persist().await;
        }
    }

    let redis = connect_redis().await;
    let state = AppState::new(storage, jwt_secret, redis);
    let app = router::router(state);

    let address = format!("{host}:{port}");
    let listener = tokio::net::TcpListener::bind(&address).await?;
    tracing::info!("LinguaQuest API siap di http://{address}");

    axum::serve(listener, app).await?;
    Ok(())
}

/// Pastikan akun demo tersedia (dibuat saat startup bila belum ada).
async fn seed_demo_account(storage: &Storage) {
    let demo_id = uuid::Uuid::parse_str("00000000-0000-4000-8000-000000000901").expect("uuid demo");
    if storage.read(|s| s.users.contains_key(&demo_id)) {
        return;
    }
    match auth::hash_password(routes::auth::DEMO_PASSWORD) {
        Ok(hash) => {
            storage.write(|s| {
                if s.users.contains_key(&demo_id) {
                    return;
                }
                s.users.insert(
                    demo_id,
                    lq_db::db::UserRow {
                        id: demo_id,
                        username: "demo".into(),
                        email: "demo@linguaquest.app".into(),
                        password_hash: Some(hash),
                        display_name: "Pelajar Hebat".into(),
                        avatar_url: None,
                        is_guest: false,
                        role: "user".into(),
                        timezone: "Asia/Jakarta".into(),
                        created_at: chrono::Utc::now(),
                    },
                );
                let mut stats = lq_db::db::StatsRow::new(demo_id);
                stats.total_xp = 320;
                stats.level = lq_db::DbState::level_for_xp(320);
                stats.streak = 4;
                stats.longest_streak = 6;
                stats.gems = 450;
                stats.freezes_available = 1;
                stats.league_tier = "emerald".into();
                s.stats.insert(demo_id, stats);
                s.wallet.push(lq_db::db::WalletRow {
                    id: 0, // id 0 = baris baru, dipersist sebagai INSERT
                    user_id: demo_id,
                    delta: 450,
                    reason: "seed:starting_gems".into(),
                    ref_id: None,
                    client_op_id: None,
                    created_at: chrono::Utc::now(),
                });
            });
            let _ = storage.persist().await;
            tracing::info!("akun demo disiapkan (demo@linguaquest.app / demo12345)");
        }
        Err(error) => tracing::warn!(%error, "gagal menyiapkan akun demo"),
    }
}

/// Isi papan peringkat dengan peserta contoh (opt-in lewat `LQ_DEMO_DATA=1`).
fn seed_leaderboard(storage: &Storage) {
    const NAMES: &[(&str, i64)] = &[
        ("Aditya R.", 850),
        ("Nabila S.", 720),
        ("Budi Santoso", 590),
        ("Citra Dewi", 510),
        ("Daniel K.", 480),
        ("Eka Pratama", 420),
        ("Gita P.", 300),
        ("Hadi W.", 120),
    ];
    storage.write(|s| {
        let season = lq_db::league::current_season(chrono::Utc::now());
        for (index, (name, xp)) in NAMES.iter().enumerate() {
            let user_id = uuid::Uuid::from_u128(0xDE00_0000_0000_0000_0000_0000_0000_0000 + index as u128);
            s.users.entry(user_id).or_insert_with(|| lq_db::db::UserRow {
                id: user_id,
                username: format!("liga_{}", index + 1),
                email: format!("liga{}@demo.linguaquest.app", index + 1),
                password_hash: None,
                display_name: (*name).to_string(),
                avatar_url: None,
                is_guest: false,
                role: "user".to_string(),
                timezone: "Asia/Jakarta".to_string(),
                created_at: chrono::Utc::now(),
            });
            let mut stats = lq_db::db::StatsRow::new(user_id);
            stats.league_tier = "emerald".to_string();
            stats.total_xp = *xp;
            s.stats.entry(user_id).or_insert(stats);
            if !s.league.iter().any(|m| m.user_id == user_id && m.season_id == season) {
                s.league.push(lq_db::db::LeagueMemberRow {
                    season_id: season.clone(),
                    group_id: "tier_emerald".to_string(),
                    user_id,
                    weekly_xp: *xp,
                });
            }
        }
    });
}

async fn connect_redis() -> Option<RedisHandle> {
    let url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6380".to_string());
    let client = match redis::Client::open(url.clone()) {
        Ok(client) => client,
        Err(error) => {
            tracing::warn!(%error, "REDIS_URL tidak valid — Redis dinonaktifkan");
            return None;
        }
    };
    match tokio::time::timeout(
        Duration::from_millis(1500),
        client.get_connection_manager(),
    )
    .await
    {
        Ok(Ok(manager)) => {
            tracing::info!(url = %url, "Redis terhubung");
            Some(Arc::new(tokio::sync::Mutex::new(manager)))
        }
        Ok(Err(error)) => {
            tracing::warn!(%error, "Redis tidak tersedia — fitur realtime dinonaktifkan");
            None
        }
        Err(_) => {
            tracing::warn!("Redis timeout — fitur realtime dinonaktifkan");
            None
        }
    }
}
