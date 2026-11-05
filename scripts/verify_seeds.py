#!/usr/bin/env python3
"""Memastikan seed SQL (PostgreSQL) dan seed Rust (in-memory) tetap identik.

- Seed SQL dimuat ke schema scratch `seed_check` memakai `psql`.
- Seed Rust dicetak oleh test `seed::dump::dump_seed_json`.
- Kedua hasil dibandingkan per tabel.

Pemakaian:
    DATABASE_URL=postgres://linguaquest:linguaquest@127.0.0.1:5433/linguaquest \\
      python3 scripts/verify_seeds.py
"""

import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MIGRATIONS = os.path.join(ROOT, "crates", "lq_db", "migrations")
DSN = os.environ.get("DATABASE_URL", "postgres://linguaquest:linguaquest@127.0.0.1:5433/linguaquest")
SCHEMA = "seed_check_verify"

# Kolom yang juga dikirim test Rust, dalam urutan yang sama.
QUERIES = {
    "courses": "SELECT id::text, from_lang, to_lang, title FROM courses ORDER BY id",
    "units": "SELECT id::text, course_id::text, position, title, theme_color FROM units ORDER BY id",
    "nodes": "SELECT id::text, unit_id::text, position, kind, title FROM nodes ORDER BY id",
    "lessons": "SELECT id::text, node_id::text, position FROM lessons ORDER BY id",
    "exercises": (
        "SELECT id::text, lesson_id::text, kind::text, position, prompt, "
        "coalesce(instruction,''), coalesce(translation,''), correct_answer, "
        "array_to_string(acceptable_answers,'|'), array_to_string(options,'|'), "
        "array_to_string(word_bank,'|'), pairs::text, coalesce(explanation,'') "
        "FROM exercises ORDER BY id"
    ),
}


def psql(sql, check=True, search_path=None):
    command = ["psql", DSN, "-v", "ON_ERROR_STOP=1", "-tA", "-F", "\x1f"]
    if search_path:
        # Opsi resmi psql untuk mengatur search_path per koneksi.
        command += ["-c", f"SET search_path TO {search_path}"]
    command += ["-c", sql]
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        raise SystemExit(f"psql gagal: {result.stderr}")
    # psql mencetak hasil dari perintah `SET search_path`; abaikan status itu.
    lines = [line for line in result.stdout.splitlines() if line != "SET"]
    return "\n".join(lines)


def read_sql_seed():
    ddl = open(os.path.join(MIGRATIONS, "0002_schema.sql")).read()
    seed = open(os.path.join(MIGRATIONS, "0003_seed_curriculum.sql")).read()
    # Default UUID tidak dipakai saat verifikasi (semua id ditulis eksplisit),
    # sehingga fungsi ekstensi diganti ekspresi yang tidak perlu ekstensi.
    ddl = ddl.replace('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";', "")
    ddl = ddl.replace("DEFAULT uuid_generate_v4()", "DEFAULT NULL")

    psql(f"DROP SCHEMA IF EXISTS {SCHEMA} CASCADE; CREATE SCHEMA {SCHEMA};")
    # Tabel/seed dibuat dengan setiap statement memakai search_path schema scratch.
    psql(f"{ddl}\n{seed}", search_path=SCHEMA)

    result = {}
    for table, query in QUERIES.items():
        rows = psql(query, search_path=SCHEMA)
        result[table] = [line.split("\x1f") for line in rows.splitlines() if line]
    psql(f"DROP SCHEMA IF EXISTS {SCHEMA} CASCADE;")
    return result


def read_rust_seed():
    env = dict(os.environ, CARGO_PROFILE_DEV_DEBUG="0")
    output = subprocess.run(
        ["cargo", "test", "-p", "lq_db", "--lib", "seed::dump::dump_seed_json", "--", "--nocapture"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        env=env,
    )
    for line in output.stdout.splitlines():
        if line.startswith("SEED_JSON:"):
            return json.loads(line[len("SEED_JSON:"):])
    raise SystemExit("Gagal memperoleh dump seed Rust:\n" + output.stdout + output.stderr)


def normalise(rows):
    """Samakan representasi array/nullantara PostgreSQL dan Rust."""
    cleaned = []
    for row in rows:
        cells = []
        for value in row:
            value = "" if value is None else str(value)
            if value.startswith("{") and value.endswith("}"):
                inner = value[1:-1]
                value = "|".join(inner.split(",")) if inner else ""
            cells.append(value.replace('"', "\\\""))
        cleaned.append(cells)
    return sorted(cleaned)


def main():
    # Test Rust dijalankan lebih dulu (build bisa lama) agar server/skrip lain
    # tidak menyentuh schema scratch di tengah proses.
    rust = read_rust_seed()
    sql = read_sql_seed()
    failures = 0
    for table in QUERIES:
        sql_rows = normalise(sql[table])
        rust_rows = normalise(rust[table])
        if sql_rows == rust_rows:
            print(f"{table:10}: OK ({len(sql_rows)} baris identik)")
            continue
        failures += 1
        print(f"{table:10}: BEDA sql={len(sql_rows)} rust={len(rust_rows)}")
        for left, right in zip(sql_rows, rust_rows):
            if left != right:
                print("  sql :", left)
                print("  rust:", right)
                break
    if failures:
        raise SystemExit(f"{failures} tabel berbeda — samakan migrations/0003_*.sql dengan seed.rs")
    print("\nSeed SQL dan Rust identik.")


if __name__ == "__main__":
    sys.exit(main())
