//! Bootstrap database PostgreSQL: migrasi DDL + seed (SRS Bab 8) dan
//! pemuatan state domain ke memori saat server start.

use anyhow::Context;
use lq_types::Exercise;
use sqlx::postgres::PgRow;
use sqlx::PgPool;

use crate::db::{AttemptRow, DbState, LessonRow, MistakeRow, NodeRow, ProgressRow, QuestProgressRow, StatsRow, UnitRow, UserRow, WalletRow};

const MIGRATIONS: &[(&str, &str)] = &[
    ("0001_extensions", include_str!("../migrations/0001_extensions.sql")),
    ("0002_schema", include_str!("../migrations/0002_schema.sql")),
    ("0003_seed_curriculum", include_str!("../migrations/0003_seed_curriculum.sql")),
    ("0004_exercise_translation", include_str!("../migrations/0004_exercise_translation.sql")),
];

/// Jalankan DDL yang belum diterapkan (idempotent, tercatat di `_lq_migrations`).
pub async fn run_migrations(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS _lq_migrations (
            name TEXT PRIMARY KEY,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )",
    )
    .execute(pool)
    .await
    .context("gagal membuat tabel _lq_migrations")?;

    for (name, ddl) in MIGRATIONS {
        let exists: Option<(String,)> = sqlx::query_as("SELECT name FROM _lq_migrations WHERE name = $1")
            .bind(name)
            .fetch_optional(pool)
            .await?;
        if exists.is_some() {
            continue;
        }

        let mut tx = pool.begin().await?;
        sqlx::raw_sql(ddl)
            .execute(&mut *tx)
            .await
            .with_context(|| format!("gagal menerapkan migrasi {name}"))?;
        sqlx::query("INSERT INTO _lq_migrations (name) VALUES ($1)")
            .bind(name)
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;
        tracing::info!(migration = name, "migrasi PostgreSQL diterapkan");
    }
    Ok(())
}

/// Muat seluruh state domain dari PostgreSQL (dipanggil sekali saat start).
pub async fn load_state(pool: &PgPool) -> anyhow::Result<DbState> {
    use sqlx::Row;
    let mut state = DbState::default();

    for row in sqlx::query(
        "SELECT id, username, email, password_hash, display_name, avatar_url, is_guest, role, timezone, created_at
         FROM users WHERE deleted_at IS NULL",
    )
    .fetch_all(pool)
    .await?
    {
        let id: uuid::Uuid = row.get("id");
        state.users.insert(
            id,
            UserRow {
                id,
                username: row.get("username"),
                email: row.get("email"),
                password_hash: row.get("password_hash"),
                display_name: row.get("display_name"),
                avatar_url: row.get("avatar_url"),
                is_guest: row.get("is_guest"),
                role: row.get("role"),
                timezone: row.get("timezone"),
                created_at: row.get("created_at"),
            },
        );
    }

    for row in sqlx::query("SELECT * FROM user_stats").fetch_all(pool).await? {
        let user_id: uuid::Uuid = row.get("user_id");
        state.stats.insert(
            user_id,
            StatsRow {
                user_id,
                total_xp: row.get("total_xp"),
                level: row.get("level"),
                streak: row.get("streak"),
                longest_streak: row.get("longest_streak"),
                last_active_date: row.get("last_active_date"),
                hearts: row.get("hearts"),
                hearts_updated_at: row.get("hearts_updated_at"),
                gems: row.get("gems"),
                freezes_available: row.get("freezes_available"),
                daily_goal_xp: row.get("daily_goal_xp"),
                league_tier: row.get("league_tier"),
            },
        );
    }

    for row in sqlx::query(
        "SELECT id, from_lang, to_lang, title, version FROM courses WHERE status = 'published' ORDER BY created_at",
    )
    .fetch_all(pool)
    .await?
    {
        state.courses.push(crate::db::CourseRow {
            id: row.get("id"),
            from_lang: row.get("from_lang"),
            to_lang: row.get("to_lang"),
            title: row.get("title"),
            version: row.get("version"),
        });
    }

    for row in sqlx::query(
        "SELECT id, course_id, position, title, description, theme_color, guidebook_json FROM units ORDER BY position",
    )
    .fetch_all(pool)
    .await?
    {
        state.units.push(UnitRow {
            id: row.get("id"),
            course_id: row.get("course_id"),
            position: row.get("position"),
            title: row.get("title"),
            description: row.get("description"),
            theme_color: row.get("theme_color"),
            guidebook: row.get("guidebook_json"),
        });
    }

    for row in sqlx::query("SELECT id, unit_id, position, kind, title, description FROM nodes ORDER BY position")
        .fetch_all(pool)
        .await?
    {
        state.nodes.push(NodeRow {
            id: row.get("id"),
            unit_id: row.get("unit_id"),
            position: row.get("position"),
            kind: row.get("kind"),
            title: row.get("title"),
            description: row.get("description"),
        });
    }

    for row in sqlx::query("SELECT id, node_id, position FROM lessons ORDER BY position")
        .fetch_all(pool)
        .await?
    {
        state.lessons.push(LessonRow {
            id: row.get("id"),
            node_id: row.get("node_id"),
            position: row.get("position"),
        });
    }

    for row in sqlx::query(
        "SELECT id, lesson_id, kind::text AS kind, position, prompt, instruction, translation,
                correct_answer, acceptable_answers, options, word_bank, pairs, explanation, audio_url
         FROM exercises ORDER BY position",
    )
    .fetch_all(pool)
    .await?
    {
        let lesson_id: uuid::Uuid = row.get("lesson_id");
        let kind: String = row.get("kind");
        let exercise = Exercise {
            id: row.get("id"),
            lesson_id: Some(lesson_id),
            kind: serde_json::from_value(serde_json::Value::String(kind))?,
            position: row.get("position"),
            prompt: row.get("prompt"),
            instruction: row.get("instruction"),
            translation: row.get("translation"),
            audio_url: row.get("audio_url"),
            options: row.get("options"),
            correct_answer: row.get("correct_answer"),
            acceptable_answers: row.get("acceptable_answers"),
            word_bank: row.get("word_bank"),
            pairs: serde_json::from_value(row.get::<serde_json::Value, _>("pairs")).unwrap_or_default(),
            explanation: row.get("explanation"),
        };
        state.exercises.entry(lesson_id).or_default().push(exercise);
    }

    for row in sqlx::query(
        "SELECT user_id, node_id, status, best_accuracy, attempts, mastered, updated_at FROM node_progress",
    )
    .fetch_all(pool)
    .await?
    {
        let user_id: uuid::Uuid = row.get("user_id");
        let node_id: uuid::Uuid = row.get("node_id");
        state.progress.insert(
            (user_id, node_id),
            ProgressRow {
                status: row.get("status"),
                best_accuracy: row.get::<f32, _>("best_accuracy") as f64,
                mastered: row.get("mastered"),
                attempts: row.get("attempts"),
                updated_at: row.get("updated_at"),
            },
        );
    }

    for row in sqlx::query("SELECT * FROM lesson_attempts ORDER BY completed_at")
        .fetch_all(pool)
        .await?
    {
        let client_op_id: uuid::Uuid = row.get("client_op_id");
        state.applied_ops.insert(client_op_id);
        state.attempts.push(AttemptRow {
            id: row.get("id"),
            user_id: row.get("user_id"),
            lesson_id: row.get("lesson_id"),
            node_id: row.get("node_id"),
            started_at: row.get("started_at"),
            completed_at: row.get("completed_at"),
            accuracy: row.get::<f32, _>("accuracy") as f64,
            correct_count: row.get("correct_count"),
            total_questions: row.get("total_questions"),
            max_combo: row.get("max_combo"),
            xp_awarded: row.get("xp_awarded"),
            hearts_lost: row.get("hearts_lost"),
            duration_ms: row.get("duration_ms"),
            client_op_id,
            answers_json: row.get("answers_json"),
        });
    }

    for row in sqlx::query("SELECT * FROM exercise_mistakes").fetch_all(pool).await? {
        let user_id: uuid::Uuid = row.get("user_id");
        let exercise_id: uuid::Uuid = row.get("exercise_id");
        state.mistakes.insert(
            (user_id, exercise_id),
            MistakeRow {
                user_id,
                exercise_id,
                prompt: row.get("prompt"),
                correct_answer: row.get("correct_answer"),
                your_answer: row.get("your_answer"),
                occurred_at: row.get("occurred_at"),
                reviewed_at: row.get("reviewed_at"),
            },
        );
    }

    for row in sqlx::query("SELECT * FROM srs_cards").fetch_all(pool).await? {
        let user_id: uuid::Uuid = row.get("user_id");
        let word: String = row.get("word");
        let card = lq_types::SrsCard {
            id: row.get("id"),
            user_id,
            word: word.clone(),
            translation: row.get("translation"),
            stability: row.get("stability"),
            difficulty: row.get("difficulty"),
            due_at: row.get("due_at"),
            last_review: row.get("last_review"),
            reps: row.get("reps"),
            lapses: row.get("lapses"),
        };
        state.cards.insert((user_id, word.to_lowercase()), card);
    }

    for row in sqlx::query(
        "SELECT id, user_id, delta, reason, ref_id, client_op_id, created_at FROM wallet_ledger ORDER BY id",
    )
    .fetch_all(pool)
    .await?
    {
        state.wallet.push(wallet_row(&row)?);
    }
    state.wallet_seq = state.wallet.iter().map(|w| w.id).max().unwrap_or(0);

    for row in sqlx::query("SELECT * FROM daily_quest_progress").fetch_all(pool).await? {
        let user_id: uuid::Uuid = row.get("user_id");
        let local_date: chrono::NaiveDate = row.get("local_date");
        let quest_code: String = row.get("quest_code");
        state.quests.insert(
            (user_id, local_date, quest_code.clone()),
            QuestProgressRow {
                user_id,
                local_date,
                quest_code,
                progress: row.get("progress"),
                claimed: row.get("claimed"),
            },
        );
    }

    for row in sqlx::query("SELECT * FROM league_members").fetch_all(pool).await? {
        state.league.push(crate::db::LeagueMemberRow {
            season_id: row.get("season_id"),
            group_id: row.get("group_id"),
            user_id: row.get("user_id"),
            weekly_xp: row.get("weekly_xp"),
        });
    }

    Ok(state)
}

fn wallet_row(row: &PgRow) -> anyhow::Result<WalletRow> {
    use sqlx::Row;
    Ok(WalletRow {
        id: row.get("id"),
        user_id: row.get("user_id"),
        delta: row.get("delta"),
        reason: row.get("reason"),
        ref_id: row.get("ref_id"),
        client_op_id: row.get("client_op_id"),
        created_at: row.get("created_at"),
    })
}

/// Apakah kurikulum sudah ter-seed.
pub async fn has_curriculum(pool: &PgPool) -> anyhow::Result<bool> {
    let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM courses").fetch_one(pool).await?;
    Ok(count.0 > 0)
}
