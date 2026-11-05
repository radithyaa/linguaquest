# Checklist & Status Pemenuhan Spesifikasi SRS: LinguaQuest

Dokumen ini memantau status implementasi terhadap **SRS v1.0** (`docs/srs_linguaquest.md`).
Untuk rincian teknis integrasi, bukti uji, dan langkah lanjutan lihat
[`INTEGRATION_STATUS.md`](INTEGRATION_STATUS.md).

Legend: ✅ selesai · ⚠️ sebagian · ❌ belum

---

## 1. Core Shared Engine (`crates/lq_core`)

- [x] ✅ **FSRS 4.5** — retrievability `R(t)=(1+F·t/S)⁻¹` dengan `F=19/81`, interval target 90 %,
      rating Again/Hard/Good/Easy.
- [x] ✅ **Answer Checker** — normalisasi NFKD, case folding, pembersihan tanda baca,
      toleransi Levenshtein ≤ 2, daftar sinonim.
- [x] ✅ **Gamifikasi** — XP `10 + bonus_akurasi + bonus_combo`, streak + Streak Freeze,
      regenerasi heart 4 jam (maks 5).
- [x] ✅ **Tes** — 7 tes lulus (`cargo test -p lq_core`).

## 2. Kontrak Tipe & Bridge (`crates/lq_types`, `crates/lq_bridge`)

- [x] ✅ DTO bersama serde `camelCase` untuk server & klien.
- [x] ✅ Fungsi bridge `#[frb(sync)]`: evaluasi jawaban, XP, FSRS, normalisasi.
- [x] ✅ Ekspor C-ABI JSON (`lq_generate_symbol`, `lq_alloc`, `lq_string_free`, `lq_version`).
- [x] ✅ Library `.so` untuk `arm64-v8a`, `armeabi-v7a`, `x86_64` (Android) dan Linux.
- [x] ✅ Uji Dart ⇄ Rust nyata (`scripts/test_ffi.sh`).
- [ ] ⚠️ `flutter_rust_bridge_codegen generate` belum dijalankan (file Dart masih manual).
- [ ] ❌ Target WASM (`wasm32-unknown-unknown`) untuk Web.

## 3. Backend & Basis Data (`crates/lq_db`, `crates/lq_api`)

### 3.1 Skema PostgreSQL (SRS Bab 8)
- [x] ✅ `users`, `auth_identities`, `refresh_tokens`
- [x] ✅ `courses`, `units`, `nodes`, `lessons`, `exercises`
- [x] ✅ `user_stats`, `xp_events` (partisi), `lesson_attempts`, `node_progress`, `exercise_mistakes`
- [x] ✅ `srs_cards`, `wallet_ledger`, `daily_quest_progress`, `league_members`
- [x] ✅ Migrasi idempotent `_lq_migrations` + seed kurikulum (SQL == Rust, terverifikasi)

### 3.2 API Axum (`/v1`)
- [x] ✅ Auth: register, login, guest, refresh (rotasi), upgrade tamu, logout
- [x] ✅ Profil & statistik, wallet
- [x] ✅ Kurikulum & detail pelajaran
- [x] ✅ Sesi: start (nonce + TTL) & complete (validasi, XP, hearts, streak, atomik, idempotent)
- [x] ✅ FSRS: ringkasan & review
- [x] ✅ Quest: ringkasan & klaim
- [x] ✅ Liga: papan peringkat (filter tier, promosi/degradasi)
- [x] ✅ Toko: katalog & pembelian dengan ledger
- [x] ✅ Sinkronisasi offline `POST /sync`
- [x] ✅ Speech-to-Text `POST /stt/transcribe`
- [x] ✅ Admin CMS: tambah unit/node, hapus unit (guard role admin)
- [x] ✅ Error RFC 9457, CORS, tracing, health check (status DB & Redis)
- [ ] ❌ Rate limiting & verifikasi email/OTP
- [ ] ❌ OAuth Google/Apple

## 4. Infrastruktur

- [x] ✅ PostgreSQL 16 (Docker, port 5433) — migrasi & seed otomatis
- [x] ✅ Redis 7 (Docker, port 6380) — leaderboard ZSET `lb:league:<season>`
- [ ] ❌ Worker terjadwal (cron) untuk rollover liga & reset quest
- [ ] ❌ CI/CD pipeline & observabilitas terpusat

## 5. Aplikasi Klien Flutter (`apps/app`)

- [x] ✅ Design system (warna brand, `TactileButton` 3D, maskot, `StatBadge`)
- [x] ✅ `ApiClient` HTTP + refresh token otomatis + pemetaan error RFC 9457
- [x] ✅ State Riverpod + `SessionController` memakai API nyata (seluruh mock dihapus)
- [x] ✅ Autentikasi: login, daftar, tamu, akun demo
- [x] ✅ Belajar: peta unit/node dari server (status current/completed/locked + master), guidebook
- [x] ✅ Sesi pelajaran: MC, word bank, typing, pair matching, fill-in-the-blank, speech
- [x] ✅ Feedback benar/salah + combo + hearts; rangkuman dari server
- [x] ✅ Latihan FSRS: kartu jatuh tempo, rating 4 tombol, review kesalahan, kamus
- [x] ✅ Quest: harian (progres nyata) + lencana bulanan + klaim
- [x] ✅ Liga: leaderboard server + zona promosi/degradasi
- [x] ✅ Toko: katalog server + pembelian tervalidasi
- [x] ✅ Profil: statistik, liga, pencapaian dari server
- [x] ✅ Admin CMS: menambah unit ke server
- [x] ✅ Offline: cache kurikulum SQLite, antrean `pending_ops`, sinkronisasi manual
- [x] ✅ Rekam mikrofon + kirim ke STT (dengan fallback input manual)
- [x] ✅ Engine Rust lokal (FFI dalam satu proses biner) dengan fallback Dart identik
- [x] ✅ 16 tes Flutter + `flutter analyze` bersih
- [x] ✅ `flutter build linux --debug` berhasil & aplikasi berjalan (engine Rust + SQLite aktif)
- [ ] ⚠️ Build APK Android belum terverifikasi di mesin ini (lihat INTEGRATION_STATUS §4.1)
- [ ] ❌ Uji perangkat fisik / integration test (`patrol`)
- [ ] ❌ In-App Purchase (Play Billing / StoreKit 2)
- [ ] ❌ Notifikasi push

## 6. Fitur SRS yang Belum Diimplementasikan

| ID | Fitur | Catatan |
|---|---|---|
| EXE-08 | Interactive Story | tipe data tersedia, belum ada UI/seed |
| EXE-09 | Character Writing | perlu canvas stroke-by-stroke |
| ONB-03 | Tes penempatan adaptif | belum |
| CUR-04 | Jump-test unit | belum |
| CUR-05 | Multi-course (pilih bahasa) | API siap, UI belum |
| SOC-01 | Pencarian teman & feed kudos | belum |
| AUTH-05/06 | Multi-perangkat & ekspor/hapus data | belum |

---

## 7. Ringkasan Verifikasi Terakhir

| Perintah | Hasil |
|---|---|
| `cargo test --workspace` | ✅ lulus (core 7, db 15, api 6, bridge 6, types 2) |
| `cd apps/app && flutter test` | ✅ 16 tes lulus |
| `flutter analyze` | ✅ No issues found |
| `scripts/smoke_api.py` | ✅ seluruh alur API OK (PostgreSQL + Redis aktif) |
| `scripts/test_ffi.sh` | ✅ Dart memanggil `lq_core` lewat `liblq_bridge.so` |
| `scripts/verify_seeds.py` | ✅ seed SQL == seed Rust |
| `flutter build linux --debug` | ✅ biner terbangun; runtime memuat Rust FFI + SQLite |
| `flutter build apk --debug` | ⚠️ belum berhasil di mesin verifikasi (lihat INTEGRATION_STATUS §4.1) |
