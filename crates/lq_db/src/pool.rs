//! Pembukaan koneksi PostgreSQL.

use std::time::Duration;

use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

#[derive(Debug, Clone)]
pub struct DbConfig {
    pub url: String,
    pub max_connections: u32,
}

impl DbConfig {
    pub fn from_env() -> Self {
        let url = std::env::var("DATABASE_URL")
            .unwrap_or_else(|_| "postgres://linguaquest:linguaquest@127.0.0.1:5433/linguaquest".to_string());
        let max_connections = std::env::var("DATABASE_MAX_CONNECTIONS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(10);
        Self { url, max_connections }
    }

    pub fn redacted(&self) -> String {
        match url::Url::parse(&self.url) {
            Ok(mut parsed) => {
                let _ = parsed.set_password(Some("***"));
                parsed.to_string()
            }
            Err(_) => "<invalid url>".to_string(),
        }
    }
}

pub type DbPool = PgPool;

pub async fn connect(cfg: &DbConfig) -> anyhow::Result<DbPool> {
    let pool = PgPoolOptions::new()
        .max_connections(cfg.max_connections)
        .acquire_timeout(Duration::from_secs(5))
        .connect(&cfg.url)
        .await?;
    Ok(pool)
}
