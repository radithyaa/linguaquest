//! State aplikasi bersama: penyimpanan, konfigurasi keamanan, dan Redis opsional.

use std::sync::Arc;

use lq_db::Storage;

#[derive(Clone)]
pub struct AppState {
    pub storage: Arc<Storage>,
    pub jwt_secret: Arc<String>,
    pub redis: Option<RedisHandle>,
    pub started_at: chrono::DateTime<chrono::Utc>,
}

pub type RedisHandle = Arc<tokio::sync::Mutex<redis::aio::ConnectionManager>>;

impl AppState {
    pub fn new(storage: Storage, jwt_secret: String, redis: Option<RedisHandle>) -> Self {
        Self {
            storage: Arc::new(storage),
            jwt_secret: Arc::new(jwt_secret),
            redis,
            started_at: chrono::Utc::now(),
        }
    }

    /// Simpan perubahan state ke penyimpanan persisten (bila aktif) dan
    /// perbarui leaderboard Redis bila tersedia.
    pub async fn commit(&self, user_id: Option<uuid::Uuid>) -> Result<(), crate::error::ApiError> {
        self.storage.persist().await?;
        if let (Some(redis), Some(user_id)) = (&self.redis, user_id) {
            let weekly_xp: i64 = self.storage.read(|state| {
                state
                    .league
                    .iter()
                    .filter(|m| m.user_id == user_id)
                    .map(|m| m.weekly_xp)
                    .sum()
            });
            if let Ok(mut conn) = redis.try_lock() {
                let season = lq_db::league::current_season(chrono::Utc::now());
                let key = format!("lb:league:{}", season);
                let _: Result<(), _> = redis::cmd("ZADD")
                    .arg(&key)
                    .arg(weekly_xp)
                    .arg(user_id.to_string())
                    .query_async(&mut *conn)
                    .await;
                let _: Result<(), _> = redis::cmd("EXPIRE").arg(&key).arg(60 * 60 * 24 * 14).query_async(&mut *conn).await;
            }
        } else if let Some(redis) = &self.redis {
            if let Ok(mut conn) = redis.try_lock() {
                let _: Result<String, _> = redis::cmd("PING").query_async(&mut *conn).await;
            }
        }
        Ok(())
    }

    pub fn redis_status(&self) -> &'static str {
        match &self.redis {
            Some(_) => "connected",
            None => "disabled",
        }
    }

    pub fn database_status(&self) -> &'static str {
        if self.storage.persistent {
            "postgres"
        } else {
            "memory"
        }
    }
}
