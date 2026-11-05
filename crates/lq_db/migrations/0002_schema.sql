CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Pengguna dan Autentikasi
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    locale VARCHAR(10) DEFAULT 'id',
    timezone VARCHAR(50) DEFAULT 'Asia/Jakarta',
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    is_guest BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);

CREATE TABLE auth_identities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(30) NOT NULL,
    provider_uid TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_provider_uid UNIQUE (provider, provider_uid)
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NULL,
    replaced_by UUID NULL
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- 2. Kurikulum dan Konten
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_lang VARCHAR(10) NOT NULL,
    to_lang VARCHAR(10) NOT NULL,
    title VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'published',
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    position INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    theme_color VARCHAR(16) NOT NULL DEFAULT '#58CC02',
    guidebook_json JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    position INT NOT NULL,
    kind VARCHAR(30) NOT NULL DEFAULT 'lesson',
    title VARCHAR(150) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    prerequisites UUID[] DEFAULT '{}'
);

CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    node_id UUID NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    position INT NOT NULL,
    content_version INT NOT NULL DEFAULT 1
);

CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    kind VARCHAR(30) NOT NULL,
    position INT NOT NULL,
    prompt TEXT NOT NULL,
    instruction TEXT NULL,
    translation TEXT NULL,
    prompt_lang VARCHAR(10) NOT NULL DEFAULT 'en',
    answer_lang VARCHAR(10) NOT NULL DEFAULT 'id',
    correct_answer TEXT NOT NULL,
    acceptable_answers TEXT[] NOT NULL DEFAULT '{}',
    options TEXT[] NOT NULL DEFAULT '{}',
    word_bank TEXT[] NOT NULL DEFAULT '{}',
    pairs JSONB NOT NULL DEFAULT '[]'::jsonb,
    explanation TEXT NULL,
    audio_url TEXT NULL,
    difficulty REAL DEFAULT 1.0
);

CREATE INDEX idx_units_course ON units(course_id, position);
CREATE INDEX idx_nodes_unit ON nodes(unit_id, position);
CREATE INDEX idx_lessons_node ON lessons(node_id, position);
CREATE INDEX idx_exercises_lesson ON exercises(lesson_id, position);

-- 3. Progres Pengguna & Log Aktivitas
CREATE TABLE user_stats (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_xp BIGINT NOT NULL DEFAULT 0,
    level INT NOT NULL DEFAULT 1,
    streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_active_date DATE NULL,
    hearts INT NOT NULL DEFAULT 5,
    hearts_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    gems INT NOT NULL DEFAULT 0,
    freezes_available INT NOT NULL DEFAULT 0,
    daily_goal_xp INT NOT NULL DEFAULT 20,
    league_tier VARCHAR(30) NOT NULL DEFAULT 'bronze'
);

-- Catatan desain: tabel xp_events pada SRS 8.1 dibuat PARTITION BY RANGE.
-- Partition otomatis per bulan dibuat oleh migrasi 0003 + backfill ledger.
CREATE TABLE xp_events (
    id BIGSERIAL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    source VARCHAR(50) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    local_date DATE NOT NULL,
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

-- Partisi default menampung seluruh data sampai worker mem-BACKFILL (*worker in progress*).
CREATE TABLE xp_events_default PARTITION OF xp_events DEFAULT;
CREATE INDEX idx_xp_events_user_date ON xp_events(user_id, local_date);

CREATE TABLE lesson_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    node_id UUID NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    accuracy REAL NOT NULL,
    correct_count INT NOT NULL,
    total_questions INT NOT NULL,
    max_combo INT NOT NULL,
    xp_awarded INT NOT NULL,
    hearts_lost INT NOT NULL,
    duration_ms BIGINT NOT NULL,
    client_op_id UUID UNIQUE NOT NULL,
    answers_json JSONB NOT NULL DEFAULT '[]'::jsonb
);
CREATE INDEX idx_lesson_attempts_user ON lesson_attempts(user_id, completed_at DESC);

CREATE TABLE node_progress (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    node_id UUID NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'current',
    best_accuracy REAL NOT NULL DEFAULT 0,
    attempts INT NOT NULL DEFAULT 0,
    mastered BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, node_id)
);

CREATE TABLE exercise_mistakes (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    prompt TEXT NOT NULL,
    correct_answer TEXT NOT NULL,
    your_answer TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ NULL,
    PRIMARY KEY (user_id, exercise_id)
);

-- 4. FSRS Spaced Repetition System
CREATE TABLE srs_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    word TEXT NOT NULL,
    translation TEXT NOT NULL,
    stability REAL NOT NULL DEFAULT 0.0,
    difficulty REAL NOT NULL DEFAULT 0.0,
    due_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_review TIMESTAMPTZ NULL,
    reps INT NOT NULL DEFAULT 0,
    lapses INT NOT NULL DEFAULT 0,
    CONSTRAINT uk_user_item UNIQUE(user_id, item_id)
);
CREATE INDEX idx_srs_cards_due ON srs_cards(user_id, due_at);

-- 5. Kebijakan Ledger Transaksi Gems (Append-Only)
CREATE TABLE wallet_ledger (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delta INT NOT NULL,
    reason VARCHAR(50) NOT NULL,
    ref_id UUID NULL,
    client_op_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX uk_wallet_op ON wallet_ledger(user_id, client_op_id) WHERE client_op_id IS NOT NULL;

-- 6. Quest & Liga
CREATE TABLE daily_quest_progress (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_date DATE NOT NULL,
    quest_code VARCHAR(40) NOT NULL,
    progress INT NOT NULL DEFAULT 0,
    claimed BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (user_id, local_date, quest_code)
);

CREATE TABLE league_members (
    season_id VARCHAR(20) NOT NULL,
    group_id VARCHAR(40) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weekly_xp BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (season_id, group_id, user_id)
);
CREATE INDEX idx_league_members_rank ON league_members(season_id, group_id, weekly_xp DESC);
