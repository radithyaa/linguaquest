//! Persistensi state ke PostgreSQL 16.
//!
//! Setiap mutation request menjalankan satu transaksi. Baris yang berarti
//! di-`UPSERT` agar database tetap menjadi sumber kebenaran, sehingga data
//! masih ada setelah server restart.

use std::sync::RwLock;

use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

use crate::db::{
    AttemptRow, CourseRow, DbState, LeagueMemberRow, LessonRow, MistakeRow, NodeRow, ProgressRow,
    QuestProgressRow, StatsRow, UnitRow, UserRow, WalletRow,
};
use lq_types::{Exercise, SrsCard};

type Tx<'a> = Transaction<'a, Postgres>;

struct Snapshot {
    users: Vec<UserRow>,
    stats: Vec<StatsRow>,
    courses: Vec<CourseRow>,
    units: Vec<UnitRow>,
    nodes: Vec<NodeRow>,
    lessons: Vec<LessonRow>,
    exercises: Vec<(Uuid, Vec<Exercise>)>,
    progress: Vec<(Uuid, Uuid, ProgressRow)>,
    attempts: Vec<AttemptRow>,
    mistakes: Vec<MistakeRow>,
    cards: Vec<SrsCard>,
    wallet: Vec<WalletRow>,
    quests: Vec<QuestProgressRow>,
    league: Vec<LeagueMemberRow>,
}

pub async fn persist_all(pool: &PgPool, state: &RwLock<DbState>) -> anyhow::Result<()> {
    let snapshot = {
        let guard = state.read().unwrap_or_else(|poisoned| poisoned.into_inner());
        Snapshot {
            users: guard.users.values().cloned().collect(),
            stats: guard.stats.values().cloned().collect(),
            courses: guard.courses.clone(),
            units: guard.units.clone(),
            nodes: guard.nodes.clone(),
            lessons: guard.lessons.clone(),
            exercises: guard.exercises.iter().map(|(id, list)| (*id, list.clone())).collect(),
            progress: guard.progress.iter().map(|((u, n), r)| (*u, *n, r.clone())).collect(),
            attempts: guard.attempts.clone(),
            mistakes: guard.mistakes.values().cloned().collect(),
            cards: guard.cards.values().cloned().collect(),
            wallet: guard.wallet.clone(),
            quests: guard.quests.values().cloned().collect(),
            league: guard.league.clone(),
        }
    };

    let mut tx = pool.begin().await?;
    for user in &snapshot.users {
        upsert_user(&mut tx, user).await?;
    }
    for stats in &snapshot.stats {
        upsert_stats(&mut tx, stats).await?;
    }
    for course in &snapshot.courses {
        sqlx::query(
            "INSERT INTO courses (id, from_lang, to_lang, title, status, version)
             VALUES ($1,$2,$3,$4,'published',$5)
             ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, version = EXCLUDED.version",
        )
        .bind(course.id)
        .bind(&course.from_lang)
        .bind(&course.to_lang)
        .bind(&course.title)
        .bind(course.version)
        .execute(&mut *tx)
        .await?;
    }
    for unit in &snapshot.units {
        upsert_unit(&mut tx, unit).await?;
    }
    for node in &snapshot.nodes {
        upsert_node(&mut tx, node).await?;
    }
    for lesson in &snapshot.lessons {
        sqlx::query(
            "INSERT INTO lessons (id, node_id, position) VALUES ($1,$2,$3)
             ON CONFLICT (id) DO UPDATE SET node_id = EXCLUDED.node_id, position = EXCLUDED.position",
        )
        .bind(lesson.id)
        .bind(lesson.node_id)
        .bind(lesson.position)
        .execute(&mut *tx)
        .await?;
    }
    for (lesson_id, list) in &snapshot.exercises {
        for exercise in list {
            upsert_exercise(&mut tx, *lesson_id, exercise).await?;
        }
    }
    for (user_id, node_id, row) in &snapshot.progress {
        sqlx::query(
            "INSERT INTO node_progress (user_id, node_id, status, best_accuracy, attempts, mastered, updated_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7)
             ON CONFLICT (user_id, node_id) DO UPDATE SET status = EXCLUDED.status,
                best_accuracy = EXCLUDED.best_accuracy, attempts = EXCLUDED.attempts,
                mastered = EXCLUDED.mastered, updated_at = EXCLUDED.updated_at",
        )
        .bind(user_id)
        .bind(node_id)
        .bind(&row.status)
        .bind(row.best_accuracy as f32)
        .bind(row.attempts)
        .bind(row.mastered)
        .bind(row.updated_at.unwrap_or_else(chrono::Utc::now))
        .execute(&mut *tx)
        .await?;
    }
    for attempt in &snapshot.attempts {
        sqlx::query(
            "INSERT INTO lesson_attempts (id, user_id, lesson_id, node_id, started_at, completed_at,
                    accuracy, correct_count, total_questions, max_combo, xp_awarded, hearts_lost,
                    duration_ms, client_op_id, answers_json)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
             ON CONFLICT (client_op_id) DO NOTHING",
        )
        .bind(attempt.id)
        .bind(attempt.user_id)
        .bind(attempt.lesson_id)
        .bind(attempt.node_id)
        .bind(attempt.started_at)
        .bind(attempt.completed_at)
        .bind(attempt.accuracy as f32)
        .bind(attempt.correct_count)
        .bind(attempt.total_questions)
        .bind(attempt.max_combo)
        .bind(attempt.xp_awarded)
        .bind(attempt.hearts_lost)
        .bind(attempt.duration_ms)
        .bind(attempt.client_op_id)
        .bind(&attempt.answers_json)
        .execute(&mut *tx)
        .await?;
    }
    for mistake in &snapshot.mistakes {
        sqlx::query(
            "INSERT INTO exercise_mistakes (user_id, exercise_id, prompt, correct_answer, your_answer, occurred_at, reviewed_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7)
             ON CONFLICT (user_id, exercise_id) DO UPDATE SET prompt = EXCLUDED.prompt,
                correct_answer = EXCLUDED.correct_answer, your_answer = EXCLUDED.your_answer,
                occurred_at = EXCLUDED.occurred_at, reviewed_at = EXCLUDED.reviewed_at",
        )
        .bind(mistake.user_id)
        .bind(mistake.exercise_id)
        .bind(&mistake.prompt)
        .bind(&mistake.correct_answer)
        .bind(&mistake.your_answer)
        .bind(mistake.occurred_at)
        .bind(mistake.reviewed_at)
        .execute(&mut *tx)
        .await?;
    }
    for card in &snapshot.cards {
        sqlx::query(
            "INSERT INTO srs_cards (id, user_id, item_id, word, translation, stability, difficulty,
                    due_at, last_review, reps, lapses)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
             ON CONFLICT (user_id, item_id) DO UPDATE SET word = EXCLUDED.word,
                translation = EXCLUDED.translation, stability = EXCLUDED.stability,
                difficulty = EXCLUDED.difficulty, due_at = EXCLUDED.due_at,
                last_review = EXCLUDED.last_review, reps = EXCLUDED.reps, lapses = EXCLUDED.lapses",
        )
        .bind(card.id)
        .bind(card.user_id)
        .bind(card.word.to_lowercase())
        .bind(&card.word)
        .bind(&card.translation)
        .bind(card.stability)
        .bind(card.difficulty)
        .bind(card.due_at)
        .bind(card.last_review)
        .bind(card.reps)
        .bind(card.lapses)
        .execute(&mut *tx)
        .await?;
    }
    for entry in &snapshot.wallet {
        if entry.id > 0 {
            continue; // Sudah tersimpan pada transaksi sebelumnya.
        }
        sqlx::query(
            "INSERT INTO wallet_ledger (user_id, delta, reason, ref_id, client_op_id, created_at)
             VALUES ($1,$2,$3,$4,$5,$6)",
        )
        .bind(entry.user_id)
        .bind(entry.delta)
        .bind(&entry.reason)
        .bind(entry.ref_id)
        .bind(entry.client_op_id)
        .bind(entry.created_at)
        .execute(&mut *tx)
        .await?;
    }
    for quest in &snapshot.quests {
        sqlx::query(
            "INSERT INTO daily_quest_progress (user_id, local_date, quest_code, progress, claimed)
             VALUES ($1,$2,$3,$4,$5)
             ON CONFLICT (user_id, local_date, quest_code) DO UPDATE SET
                progress = EXCLUDED.progress, claimed = EXCLUDED.claimed",
        )
        .bind(quest.user_id)
        .bind(quest.local_date)
        .bind(&quest.quest_code)
        .bind(quest.progress)
        .bind(quest.claimed)
        .execute(&mut *tx)
        .await?;
    }
    for member in &snapshot.league {
        sqlx::query(
            "INSERT INTO league_members (season_id, group_id, user_id, weekly_xp) VALUES ($1,$2,$3,$4)
             ON CONFLICT (season_id, group_id, user_id) DO UPDATE SET weekly_xp = EXCLUDED.weekly_xp",
        )
        .bind(&member.season_id)
        .bind(&member.group_id)
        .bind(member.user_id)
        .bind(member.weekly_xp)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;
    Ok(())
}

async fn upsert_user(tx: &mut Tx<'_>, user: &UserRow) -> anyhow::Result<()> {
    sqlx::query(
        "INSERT INTO users (id, username, email, password_hash, display_name, avatar_url, is_guest, role, timezone, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
         ON CONFLICT (id) DO UPDATE SET username = EXCLUDED.username, email = EXCLUDED.email,
            password_hash = EXCLUDED.password_hash, display_name = EXCLUDED.display_name,
            avatar_url = EXCLUDED.avatar_url, is_guest = EXCLUDED.is_guest, role = EXCLUDED.role,
            timezone = EXCLUDED.timezone, updated_at = NOW()",
    )
    .bind(user.id)
    .bind(&user.username)
    .bind(&user.email)
    .bind(&user.password_hash)
    .bind(&user.display_name)
    .bind(&user.avatar_url)
    .bind(user.is_guest)
    .bind(&user.role)
    .bind(&user.timezone)
    .bind(user.created_at)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

async fn upsert_stats(tx: &mut Tx<'_>, stats: &StatsRow) -> anyhow::Result<()> {
    sqlx::query(
        "INSERT INTO user_stats (user_id, total_xp, level, streak, longest_streak, last_active_date,
                hearts, hearts_updated_at, gems, freezes_available, daily_goal_xp, league_tier)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
         ON CONFLICT (user_id) DO UPDATE SET total_xp = EXCLUDED.total_xp, level = EXCLUDED.level,
            streak = EXCLUDED.streak, longest_streak = EXCLUDED.longest_streak,
            last_active_date = EXCLUDED.last_active_date, hearts = EXCLUDED.hearts,
            hearts_updated_at = EXCLUDED.hearts_updated_at, gems = EXCLUDED.gems,
            freezes_available = EXCLUDED.freezes_available, daily_goal_xp = EXCLUDED.daily_goal_xp,
            league_tier = EXCLUDED.league_tier",
    )
    .bind(stats.user_id)
    .bind(stats.total_xp)
    .bind(stats.level)
    .bind(stats.streak)
    .bind(stats.longest_streak)
    .bind(stats.last_active_date)
    .bind(stats.hearts)
    .bind(stats.hearts_updated_at)
    .bind(stats.gems)
    .bind(stats.freezes_available)
    .bind(stats.daily_goal_xp)
    .bind(&stats.league_tier)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

async fn upsert_unit(tx: &mut Tx<'_>, unit: &UnitRow) -> anyhow::Result<()> {
    sqlx::query(
        "INSERT INTO units (id, course_id, position, title, description, theme_color, guidebook_json)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         ON CONFLICT (id) DO UPDATE SET position = EXCLUDED.position, title = EXCLUDED.title,
            description = EXCLUDED.description, theme_color = EXCLUDED.theme_color,
            guidebook_json = EXCLUDED.guidebook_json",
    )
    .bind(unit.id)
    .bind(unit.course_id)
    .bind(unit.position)
    .bind(&unit.title)
    .bind(&unit.description)
    .bind(&unit.theme_color)
    .bind(&unit.guidebook)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

async fn upsert_node(tx: &mut Tx<'_>, node: &NodeRow) -> anyhow::Result<()> {
    sqlx::query(
        "INSERT INTO nodes (id, unit_id, position, kind, title, description) VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT (id) DO UPDATE SET position = EXCLUDED.position, kind = EXCLUDED.kind,
            title = EXCLUDED.title, description = EXCLUDED.description",
    )
    .bind(node.id)
    .bind(node.unit_id)
    .bind(node.position)
    .bind(&node.kind)
    .bind(&node.title)
    .bind(&node.description)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

async fn upsert_exercise(tx: &mut Tx<'_>, lesson_id: Uuid, exercise: &Exercise) -> anyhow::Result<()> {
    let kind = serde_json::to_value(exercise.kind)?
        .as_str()
        .unwrap_or("multiple_choice")
        .to_string();
    sqlx::query(
        "INSERT INTO exercises (id, lesson_id, kind, position, prompt, instruction, translation,
                correct_answer, acceptable_answers, options, word_bank, pairs, explanation, audio_url)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
         ON CONFLICT (id) DO UPDATE SET kind = EXCLUDED.kind, position = EXCLUDED.position,
            prompt = EXCLUDED.prompt, instruction = EXCLUDED.instruction,
            translation = EXCLUDED.translation,
            correct_answer = EXCLUDED.correct_answer, acceptable_answers = EXCLUDED.acceptable_answers,
            options = EXCLUDED.options, word_bank = EXCLUDED.word_bank, pairs = EXCLUDED.pairs,
            explanation = EXCLUDED.explanation, audio_url = EXCLUDED.audio_url",
    )
    .bind(exercise.id)
    .bind(lesson_id)
    .bind(kind)
    .bind(exercise.position)
    .bind(&exercise.prompt)
    .bind(&exercise.instruction)
    .bind(&exercise.translation)
    .bind(&exercise.correct_answer)
    .bind(&exercise.acceptable_answers)
    .bind(&exercise.options)
    .bind(&exercise.word_bank)
    .bind(serde_json::to_value(&exercise.pairs)?)
    .bind(&exercise.explanation)
    .bind(&exercise.audio_url)
    .execute(&mut **tx)
    .await?;
    Ok(())
}
