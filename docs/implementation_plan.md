# Rencana Implementasi: LinguaQuest Versi Flutter & Rust (Sesuai SRS)

Dokumen ini menguraikan rencana teknis dan arsitektur untuk membangun implementasi penuh aplikasi **LinguaQuest** berbasis **Flutter** dan **Rust** sesuai dengan dokumen spesifikasi kebutuhan sistem (**SRS** di `srs_linguaquest.md`), dengan tetap mengadopsi bahasa desain, estetika visual, komponen UI gamifikasi, serta alur pengalaman yang sudah ada pada prototipe web saat ini.

---

## 1. Deskripsi Tujuan & Konteks

- **Konteks:** Saat ini, kodebase pada root direktori merupakan implementasi prototipe web berbasis TypeScript, React, Vite, dan Tailwind CSS.
- **Tujuan:** Membuat proyek baru (dalam folder terstruktur khusus seperti `linguaquest_native/` atau struktur monorepo `apps/` dan `crates/` sesuai SRS Bab 4) yang mengimplementasikan spesifikasi SRS secara utuh:
  1. **Modul Bersama (`lq_core` - Rust):** Mesin penilaian jawaban (Unicode NFKD, toleransi typo Levenshtein), algoritma FSRS 4.5, kalkulasi XP, regenerasi Heart, dan logika Streak.
  2. **Backend Service (`lq_api` / `crates/` - Rust Axum):** API modular monolith Axum untuk otentikasi JWT/Argon2id, session lifecycle, transaksi atomic database PostgreSQL, Redis leaderboard ZSET, dan offline sync queue.
  3. **Aplikasi Klien (`linguaquest_flutter` / `apps/app` - Flutter):** Klien Flutter (Mobile, Desktop, Web) yang mereplikasi tampilan visual dari React Web saat ini (3D tactile buttons, Duolingo-style green `#58CC02`, Blue `#1CB0F6`, Orange `#FF9600`, Red `#FF4B4B`, Mascot expressions, top bar stats, path kurikulum vertikal bergelombang, exercise types, FSRS flashcard practice, daily quests, weekly leagues, shop items, profile achievements, admin CMS modal).
  4. **Checklist & Tracking:** Dokumen status checklist pengerjaan dan pelacakan implementasi secara komprehensif.

---

## 2. Struktur Direktori Proyek Baru

Sesuai dengan **SRS Bab 4 (Struktur Repositori Monorepo)**, struktur folder baru akan dibuat di dalam direktori `native/` (atau direktori monorepo baru):

```text
native/
├── apps/
│   ├── app/                                 # Flutter Client Application (Android, iOS, Web, Windows, macOS, Linux)
│   │   ├── pubspec.yaml
│   │   ├── analysis_options.yaml
│   │   ├── assets/
│   │   │   ├── audio/
│   │   │   ├── images/
│   │   │   └── data/curriculum.json
│   │   └── lib/
│   │       ├── main.dart
│   │       ├── core/
│   │       │   ├── constants/colors.dart
│   │       │   ├── router/app_router.dart   # go_router navigasi sesuai Bab 6 SRS
│   │       │   ├── theme/app_theme.dart     # Font Inter, 3D button styling, palet warna
│   │       │   └── widgets/
│   │       │       ├── tactile_button.dart  # 3D Pressed button Flutter (seperti TactileButton.tsx)
│   │       │       ├── mascot.dart          # Komponen maskot SVG/CustomPaint (seperti Mascot.tsx)
│   │       │       └── stat_badge.dart      # Heart, Gems, Streak badge
│   │       ├── features/
│   │       │   ├── learn/                   # Peta jalur kurikulum (LearnView), Unit nodes, Guidebook modal
│   │       │   ├── lesson/                  # Sesi pelajaran, progress bar, 9 tipe exercise, summary
│   │       │   ├── practice/                # Hub latihan FSRS 4.5, mistake review, kosakata
│   │       │   ├── quests/                  # Daily quests & monthly badges
│   │       │   ├── league/                  # Papan peringkat Liga mingguan (10 tier)
│   │       │   ├── shop/                    # Toko Gems, Refill Hearts, Streak Freeze, Premium
│   │       │   ├── profile/                 # Statistik akun, friend list, lencana achievement
│   │       │   └── admin/                   # Modal CMS admin editor unit & soal
│   │       └── data/
│   │           ├── models/                  # Course, Unit, Lesson, Exercise, UserStats
│   │           ├── repositories/            # Offline-first repository + sync queue
│   │           └── ffi/                     # Bridge bindings ke lq_core Rust
│   └── admin/                               # Portal Admin Opsional (Flutter Web / CMS)
├── crates/
│   ├── Cargo.toml                           # Cargo Workspace
│   ├── lq_core/                             # Shared Business Logic Engine (Rust Native & WASM)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── fsrs.rs                      # FSRS 4.5 Spaced Repetition (Again, Hard, Good, Easy)
│   │       ├── answer_checker.rs            # Normalisasi NFKD, Levenshtein distance <= 2
│   │       ├── gamification.rs              # Formula XP, Streak timezone, Hearts 4h regen
│   │       └── sync_payload.rs              # UUID client_op_id & validation
│   ├── lq_types/                            # Shared DTOs, Enums, API Models
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── lq_db/                               # PostgreSQL SQLx Migrations & Queries (Bab 8 SRS)
│   │   ├── Cargo.toml
│   │   ├── migrations/
│   │   └── src/lib.rs
│   └── lq_api/                              # Backend Server REST/WebSocket (Axum 0.8)
│       ├── Cargo.toml
│       └── src/
│           ├── main.rs
│           ├── routes/                      # auth, curriculum, sessions, league, shop, admin
│           └── state.rs
└── docs/
    └── CHECKLIST.md                         # List Checklist Pelacakan Spesifikasi SRS
```

---

## 3. Rencana Komponen & Implementasi

### A. Modul Rust (`crates/lq_core`)
- [x] Mendefinisikan Cargo Workspace di `native/crates/Cargo.toml`.
- [x] Implementasi **FSRS 4.5** di Rust (`lq_core`):
  - Model kartu SRS: Stability ($S$), Difficulty ($D$), Reps, Lapses, Due Date.
  - Formula Retrievability $R(t) = (1 + \frac{19}{81} \cdot \frac{t}{S})^{-1}$.
  - Transisi status untuk input rating `Again (1)`, `Hard (2)`, `Good (3)`, `Easy (4)`.
- [x] Implementasi **Answer Checker** (`answer_checker.rs`):
  - Normalisasi teks Unicode & case folding.
  - Perhitungan jarak Levenshtein (toleransi salah ketik / typo $\le 2$).
  - Validasi untuk 9 jenis latihan (Multiple Choice, Word Bank, Typing, Listening, Pair Matching, Fill in the Blank, Speech, Story, Character Writing).
- [x] Implementasi **Gamification Calculator** (`gamification.rs`):
  - Formula XP: $\text{XP}_{\text{total}} = 10 + \text{accuracy\_bonus} + \text{combo\_bonus}$ (SRS Bab 9.1).
  - Logika Streak dengan Streak Freeze dan Timezone handling (SRS Bab 9.2).
  - Regenerasi Heart (maksimal 5, 1 Heart per 4 jam).
- [x] Unit Test lengkap dengan `cargo test` untuk memverifikasi 100% akurasi logika core.

### B. Backend Rust Axum (`crates/lq_api` & `crates/lq_db`)
- [x] DDL Skema PostgreSQL (Users, Auth Identities, Courses, Units, Nodes, Lessons, Exercises, User Stats, XP Events, SRS Cards, Wallet Ledger) sesuai SRS Bab 8.
- [x] Modul Router Axum `/v1/`:
  - `POST /v1/auth/register`, `POST /v1/auth/login` (Argon2id + JWT).
  - `GET /v1/courses`, `GET /v1/courses/:id/curriculum`.
  - `POST /v1/sessions/start`, `POST /v1/sessions/complete` (Atomic session processing).
  - `GET /v1/practice/fsrs`, `POST /v1/practice/review`.
  - `GET /v1/league/leaderboard` (ZSET mock/store).
  - `GET /v1/shop/catalog`, `POST /v1/shop/buy`.
  - `GET /v1/admin/...` (Course editor, user moderation).

### C. Aplikasi Flutter (`native/apps/app`)
- [x] Konfigurasi Proyek Flutter multiplatform (`pubspec.yaml` lengkap dengan dependencies: `flutter_riverpod`, `go_router`, `google_fonts`, dll.).
- [x] **Design System & Visual Identitas:**
  - Replikasi exact visual tema web: Warna Hex `#58CC02` (Green), `#1CB0F6` (Blue), `#FF9600` (Orange), `#FF4B4B` (Red), `#CE82FF` (Purple), `#E5E5E5` (Borders).
  - Komponen `TactileButton`: tombol bergaya 3D dengan shadow bawah tebal dan animasi kompresi saat ditekan.
  - Komponen `Mascot`: karakter maskot burung interaktif LinguaQuest dengan berbagai mood (happy, cheering, thinking, sad, celebrating).
  - Komponen `StatBadge`: indikator TopBar untuk Gems, Hearts, dan Streak.
- [x] **Layout Adaptif & Rute (`go_router`):**
  - Desktop / Web (> 1024 dp): Sidebar kiri permanen, area konten tengah, panel sidebar kanan (Streak widget, Quests widget, League widget).
  - Tablet (600 - 1024 dp): Navigation Rail.
  - Mobile (< 600 dp): Bottom Navigation Bar 5 tab.
  - Fullscreen headless modal untuk Sesi Pelajaran (`/lesson/:id`).
- [x] **Implementasi Halaman Utama (sesuai Web saat ini):**
  1. **Learn Screen:** Jalur belajar vertikal dengan snake/curved path, unit header bertema, status node (Completed, Active/Current, Locked), dan Unit Guidebook dialog.
  2. **Lesson Session & Exercise Engine:**
     - Progress bar animasi, indikator sisa Hearts.
     - Exercise 1: Pilihan Ganda (Multiple Choice).
     - Exercise 2: Word Bank Builder (Menyusun kata dari bank kata).
     - Exercise 3: Mengetik Terjemahan (Typing translation dengan typo tolerance).
     - Exercise 4: Listening / Audio prompt.
     - Exercise 5: Pair Matching (Mencocokkan pasangan kata).
     - Feedback Sheet (Hijau untuk Jawaban Benar, Merah untuk Jawaban Salah beserta penjelasan).
     - Lesson Summary Screen dengan animasi perolehan XP, Akurasi, Combo, dan tombol Lanjut.
  3. **Practice Screen:** Hub Latihan Mandiri FSRS 4.5 (Kartu kata, rating Again/Hard/Good/Easy), Review Kesalahan (Mistakes), dan Kamus Kosakata (Words mastered).
  4. **Quests Screen:** Tantangan harian (Daily Quests) dengan progres bar & reward Gems, serta Monthly Badge Quest.
  5. **League Screen:** Leaderboard mingguan 30 pengguna, tier badges (Bronze ke Diamond), penanda zona promosi (Top 5) & degradasi (Bottom 5).
  6. **Shop Screen:** Pembelian Heart Refill, Streak Freeze, Double XP boost, kosmetik maskot, dan banner Super LinguaQuest.
  7. **Profile Screen:** Statistik akumulasi XP, streak terbaik, riwayat liga, dan grid piala pencapaian (Achievements).
  8. **Admin CMS Dialog:** Pengelolaan kurikulum bahasa, penambahan unit dan soal latihan secara dinamis.

### D. Dokumen Checklist Pelacakan (`native/docs/CHECKLIST.md`)
- [x] Membuat dokumen checklist terperinci yang mencakup seluruh poin SRS (AUTH, ONB, CUR, EXE, LES, GAM, REV, SOC, SHOP, NTF, OFF, ADM) dengan status verifikasi (*checked/in-progress/planned*).

---

## 4. Rencana Verifikasi

### Otomatis (Automated Tests)
1. **Rust Core Logic:**
   - Jalankan `cargo test --workspace` di dalam direktori `native/crates` untuk memastikan semua test FSRS, Levenshtein, kalkulator XP, dan regenerasi Heart lulus.
2. **Rust Backend Server:**
   - Jalankan `cargo check` & `cargo test -p lq_api` untuk memverifikasi routing API dan kontrak endpoint.
3. **Flutter Static Analysis:**
   - Melakukan validasi sintaks Dart dan struktur widget pada proyek Flutter.

### Manual
- Memeriksa struktur kode Flutter untuk memastikan konsistensi tema, styling 3D button, dan alur rute navigasi identik dengan prototipe web saat ini.

---

> [!NOTE]
> Toolchain Rust (`rustc 1.97.1` & `cargo 1.97.1`) sudah terpasang dan siap digunakan di sistem untuk membangun dan menguji `crates/`. Kode Flutter dirancang modular dengan standar Flutter 3.x / Dart 3 sehingga dapat langsung dijalankan dengan `flutter run` di perangkat atau lingkungan Flutter pengguna.
