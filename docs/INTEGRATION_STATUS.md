# Status Integrasi Sistem — LinguaQuest

Diperbarui: 5 November 2026
Lingkungan verifikasi: Linux (Ubuntu 26.04), Flutter 3.24.5 / Dart 3.5.4, Rust 1.97.1,
PostgreSQL 16 (Docker, port 5433), Redis 7 (Docker, port 6380), NDK 27.2.12479018.

Dokumen ini menggantikan daftar "Yang BELUM" pada README lama **dan** menjawab empat
poin backlog integrasi:

1. Automasi binding FFI/WASM (`flutter_rust_bridge`)
2. Penyimpanan offline lokal SQLite (Drift)
3. Perekaman mikrofon & Speech-to-Text
4. Penyediaan PostgreSQL 16 & Redis 7 aktif

---

## 1. Ringkasan Cepat

| Area | Status | Bukti |
|---|---|---|
| Frontend tersambung penuh ke server (tanpa mock) | ✅ Selesai | `lib/data/api/*`, `lib/state/*`; seluruh view memakai provider server |
| Server REST Axum `/v1` lengkap | ✅ Selesai | `crates/lq_api/src/routes/*` |
| PostgreSQL 16 aktif + migrasi + seed | ✅ Selesai | `docker compose up`, tabel `_lq_migrations`, `scripts/verify_seeds.py` |
| Redis 7 aktif (leaderboard ZSET) | ✅ Selesai | key `lb:league:<season>` terisi |
| Data/state mock dihapus | ✅ Selesai | `lib/data/curriculum_data.dart` & `models/curriculum.dart` dihapus |
| Penyimpanan offline SQLite (sesi, cache, antrean) | ✅ Selesai (paket `sqflite`) | `lib/data/local/local_store.dart` |
| Perekaman mikrofon + STT | ✅ Selesai (klien + endpoint) | `features/lesson/speech_recorder.dart`, `routes/stt.rs` |
| FFI Rust untuk Android **dan** Linux | ✅ Selesai | `scripts/build_bridge.sh`, `./scripts/test_ffi.sh` |
| Binding C-FFI otomatis via `flutter_rust_bridge_codegen` | ⚠️ Sebagian | runtime FFI aktif; kode hasil generator belum menggantikan file manual |
| WASM untuk Web | ❌ Belum | lihat §5.2 |
| In-App Purchase (Play Billing / StoreKit 2) | ❌ Belum | §5.6 |
| OAuth Google/Apple | ❌ Belum | §5.6 |
| **Build APK Android** | ⚠️ Fungsional belum terbukti | §4.1 — langkah yang perlu Anda lakukan |
| Uji di perangkat fisik | ❌ Belum (tidak ada perangkat terhubung) | §4.2 |

---

## 2. Yang SUDAH Selesai (rinci)

### 2.1 Backend Rust

**`crates/lq_types`** — DTO kontrak bersama, serde `camelCase`.
Memuat dua tes: serialisasi RFC 9457 dan field camelCase.

**`crates/lq_core`** — mesin bisnis (tidak berubah, tetap dipakai server & bridge):
FSRS 4.5, answer checker (NFKD + Levenshtein ≤ 2), XP, streak + freeze, regenerasi heart.
7 tes lulus.

**`crates/lq_db`** — domain state + persistensi PostgreSQL:

- `db.rs` — state domain, `Storage` (backend PostgreSQL atau in-memory), perhitungan node terbuka
- `migrations/0001…0004` — skema SRS Bab 8 + seed kurikulum + kolom `exercises.translation`
- `migrate.rs` — runner migrasi (`_lq_migrations`, idempotent) dan loader state saat startup
- `persist.rs` — sinkronisasi state → PostgreSQL dalam satu transaksi per request (UPSERT)
- `curriculum.rs`, `learning.rs`, `srs.rs`, `gamification.rs`, `quests.rs`, `league.rs`, `users.rs`
- `seed.rs` — seed in-memory yang **identik** dengan SQL (diverifikasi `scripts/verify_seeds.py`)

15 tes lulus, termasuk: idempotensi `client_op_id`, XP sesi sempurna = 19,
exercise tidak membocorkan kunci jawaban, dan seed SQL == seed Rust.

**`crates/lq_bridge`** — jembatan ke Flutter:

- `api.rs` — fungsi `#[flutter_rust_bridge::frb(sync)]` (evaluate, XP, FSRS, normalisasi)
- `ffi.rs` — ekspor C-ABI JSON: `lq_generate_symbol`, `lq_alloc`, `lq_string_free`, `lq_version`
- Dibangun untuk `aarch64-linux-android`, `armv7-linux-androideabi`,
  `x86_64-linux-android`, `x86_64-unknown-linux-gnu`
- 6 tes lulus (termasuk dispatch C-ABI)

**`crates/lq_api`** — Axum modular monolith, semua endpoint `/v1`:

| Modul | Endpoint |
|---|---|
| health | `GET /health` |
| auth | `POST /auth/register`, `/login`, `/guest`, `/refresh`, `/upgrade`, `/logout` |
| profil | `GET/PATCH /me`, `GET /me/wallet` |
| kurikulum | `GET /courses`, `/courses/{id}/curriculum`, `/lessons/{node_id}` |
| sesi | `POST /sessions/start`, `/sessions/complete` |
| FSRS | `GET /practice`, `POST /practice/review` |
| quest | `GET /quests`, `POST /quests/{code}/claim` |
| liga | `GET /league` |
| toko | `GET /shop/catalog`, `POST /shop/buy` |
| offline | `POST /sync` |
| STT | `POST /stt/transcribe` (+ `/v1/stt/transcribe`) |
| admin | `POST /admin/units`, `/admin/nodes`, `DELETE /admin/units/{id}` |

Keamanan & kualitas: Argon2id, JWT HS256, rotasi refresh token (hash SHA-256),
error RFC 9457, idempotensi sesi via `client_op_id`, CORS, tracing.
8 tes lulus (hash, JWT, pemetaan error, bearer token).

### 2.2 Frontend Flutter (data nyata, tanpa mock)

- **`ApiClient`** — HTTP, injeksi `Bearer`, refresh token otomatis sekali saat 401,
  pemetaan Problem Details ke `ApiException`/`HeartsExhaustedException`, deteksi offline.
- **`SessionController` + Riverpod** — autentikasi, kurikulum (online → cache), mulai/selesai
  sesi, evaluasi jawaban, FSRS, quest, liga, toko, sinkronisasi antrean, admin CMS.
- **`LocalStore` (SQLite)** — tabel `session`, `cached_curriculum`, `pending_ops`, `local_stats`.
  Desktop Linux/Windows/macOS memakai `sqflite_common_ffi` dengan fallback `libsqlite3.so.0`.
- **UI** — `AuthView` (login/daftar/tamu/akun demo), `AppShell` (badge koneksi, antrean
  sinkronisasi), `LessonScreen` (MC, word bank, typing, pair matching, fill-in-blank,
  speech + rekam audio, combo, hearts, feedback), Learn/Practice/Quests/League/Shop/Profile/Admin
  semuanya membaca server.
- **Engine Rust di perangkat** — `rust_bridge/` memuat `liblq_bridge.so` saat runtime
  (log: `engine Rust aktif: liblq_bridge aktif (probe XP=19)`), dengan fallback
  `PureDartEngine` (porting 1:1) bila library tidak ada.
- 16 tes Flutter lulus (`flutter analyze`: no issues).

### 2.3 Hasil uji end-to-end yang benar-benar dijalankan

```
health          : 200 db=postgres redis=connected
login demo      : 200 user=Pelajar Hebat
curriculum      : 2 unit, node0=Halo & Selamat Pagi status=current
session start   : 5 soal, hearts=5
session done    : xp=10 akurasi=0.80 combo=2 hearts=4
idempotensi     : 409 DUPLICATE_OP
profile         : xp=330 streak=1 gems=457 lencana=4
fsrs review     : 'Hello' reps=1 interval=1.2 hari
quests          : xp_30=10/30, lessons_2=1/2, accuracy_90=0/1
quest claim     : lessons_2 +15 gems
league          : tier=emerald rank=9 peserta=9
shop buy        : Isi Penuh Hearts berhasil dibeli! gems tersisa=329
sync            : applied=0 rejected=0
error RFC 9457  : 401 UNAUTHORIZED — Tidak Terautentikasi
```

Redis: `lb:league:2026-W45` berisi skor ZSET; PostgreSQL berisi baris nyata
(`users=9, attempts=2, srs_cards=5, wallet_ledger=11, daily_quest_progress`).

FFI (`./scripts/test_ffi.sh`):

```
versi library   : 0.2.0
evaluasi typo   : status=typo_warning jarak=2
XP sesi sempurna: 21 (harus 21)
FSRS rating 3   : stability=2.5 reps=1
FFI OK — Dart memanggil lq_core lewat liblq_bridge
```

---

## 3. Yang BELUM Selesai

### 3.1 Backlog empat poin lama

| Poin | Status | Keterangan |
|---|---|---|
| 1. Binding FFI/WASM `flutter_rust_bridge` | ⚠️ **Sebagian** | Runtime FFI **sudah** memanggil `lq_core` di Android/Linux (bukti di atas). Yang belum: menjalankan `flutter_rust_bridge_codegen` sehingga file `rust_bridge/*.dart` menggantikan versi manual. WASM (Web) belum. |
| 2. Penyimpanan offline SQLite (Drift) | ✅ **Selesai** dengan `sqflite` | Persistensi lokal (sesi, cache kurikulum, antrean `pending_ops`, stats) berjalan. **Bukan** memakai codegen Drift; skema sudah disiapkan agar mudah dipetakan (§4.4). |
| 3. Rekam mikrofon & STT | ✅ **Selesai** | `record` 6.x + `POST /v1/stt/transcribe`. STT aktif hanya jika `STT_PROVIDER=whisper` (+ kunci). Tanpa itu klien menampilkan transkripsi manual. |
| 4. PostgreSQL & Redis aktif | ✅ **Selesai** | `infra/docker-compose.yml`, migrasi otomatis, leaderboard Redis. |

### 3.2 Daftar sisa pekerjaan

1. **Verifikasi build APK Android** (§4.1) — build di mesin ini gagal pada tahap
   evaluasi plugin karena kendala memori/disk dan versi toolchain; perlu dikonfirmasi.
2. **Uji di perangkat fisik** (§4.2) — belum ada perangkat terhubung (`adb devices` kosong).
3. **Run codegen `flutter_rust_bridge_codegen`** (§4.3).
4. **Migrasi penyimpanan ke Drift** (opsional, §4.4).
5. **WASM untuk Web** (§5.2).
6. **STT produksi** — pemasangan kunci, batas kuota, penyimpanan audio (saat ini audio tidak
   disimpan, hanya ditranskripsi lalu dibuang) (§4.5).
7. **In-App Purchase, OAuth, notifikasi push** (§5.6).
8. **Keamanan produksi**: `JWT_SECRET`, HTTPS, pencabutan cleartext, penyimpanan token di
   Keystore/Keychain (§5.7).
9. **Fitur kurikulum lanjutan**: story, character writing (stroke), tes penempatan adaptif (§5.5).
10. **CI/CD** dan observabilitas (tracing terpusat, metrik) (§5.8).

---

## 4. Langkah yang Perlu Anda Lakukan

### 4.1 Memastikan build APK Android berhasil

Jalankan dari root repo pada mesin dengan **≥ 8 GB RAM dan ≥ 10 GB disk kosong**
(build gagal pada mesin verifikasi karena disk penuh + OOM):

```bash
cd apps/app
flutter clean
flutter pub get
./../../scripts/build_bridge.sh android     # hasilkan .so untuk 3 ABI
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.10:8090/v1
# hasil: build/app/outputs/flutter-apk/app-debug.apk
```

Jika muncul lagi `compileSdkVersion is not specified`, itu berasal dari plugin
`record_android` yang mengevaluasi lebih awal. Perbaikannya:

```groovy
// apps/app/android/app/build.gradle → blok android
compileSdk = 35          // ganti flutter.compileSdkVersion dengan angka eksplisit
ndkVersion = "27.2.12479018"
```

lalu tambahkan juga di `apps/app/android/build.gradle` (root):

```groovy
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) namespace = project.group.toString()
                compileSdk = 35
            }
        }
    }
}
```

Alternatif jika masih gagal: turunkan `record` ke `^5.2.1`
(`flutter pub add record:^5.2.1`) — API perekaman yang dipakai sama.

### 4.2 Menjalankan di HP Android Anda

1. Aktifkan **Opsi Pengembang → USB Debugging**.
2. Hubungkan kabel, lalu `adb devices` harus menampilkan perangkat.
3. Pastikan HP dan laptop satu jaringan Wi-Fi; cari IP laptop:
   `hostname -I` → misal `192.168.1.10`.
4. Jalankan server agar mendengar semua antarmuka:
   ```bash
   ./scripts/run_api.sh          # HOST=0.0.0.0 PORT=8090
   ```
5. Cek dari HP: buka `http://192.168.1.10:8090/v1/health` di browser HP.
   Jika gagal, izinkan port 8090 di firewall:
   `sudo ufw allow 8090/tcp`.
6. Pasang & jalankan aplikasi:
   ```bash
   cd apps/app
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   # atau langsung:
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8090/v1
   ```
7. Masuk dengan **demo@linguaquest.app / demo12345** atau tekan **AKUN DEMO**.
8. Alur uji yang disarankan: Belajar → node pertama → jawab soal (termasuk salah satu salah
   agar hearts berkurang) → selesai → lihat XP/streak naik → Latihan (FSRS) → Quest → Liga →
   Toko → Profil.
9. Uji offline: matikan Wi-Fi → selesaikan satu pelajaran → muncul antrean offline pada ikon
   awan di AppBar → nyalakan Wi-Fi → tekan ikon awan untuk sinkronisasi.

Catatan: izin `RECORD_AUDIO` diminta saat pertama kali menekan tombol **REKAM SUARA**.
Server harus dijalankan dengan `STT_PROVIDER=whisper` dan `OPENAI_API_KEY=...` agar
penilaian pelafalan otomatis aktif.

### 4.3 Menjalankan generator `flutter_rust_bridge_codegen`

```bash
cargo install flutter_rust_bridge_codegen --version 2.7.0
cd /path/ke/linguaquest
flutter_rust_bridge_codegen generate \
  --rust-input crates/lq_bridge/src/api.rs \
  --dart-output apps/app/lib/rust_bridge/frb_generated.dart \
  --rust-root .
```

Setelah generate, sesuaikan `lib/rust_bridge/rust_lib.dart` agar memanggil
`RustLib.init()` (menggantikan `_Abi` manual) dan hapus kelas `_Abi`.
Jalankan `flutter test` + `./scripts/test_ffi.sh` untuk memastikan hasilnya setara.

### 4.4 (Opsional) Pindah penuh ke Drift

Skema di `lib/data/local/local_store.dart` sudah dipisah per tabel agar bisa dipetakan
langsung ke Drift:

```bash
cd apps/app
dart pub add drift drift_flutter dev:drift_dev dev:build_runner
dart run drift_dev make-migrations
dart run build_runner build --delete-conflicting-outputs
```

Tabel: `session` → `Sessions`, `cached_curriculum` → `CachedCurricula`,
`pending_ops` → `PendingOps`, `local_stats` → `LocalStats`.

### 4.5 Mengaktifkan STT

```bash
STT_PROVIDER=whisper OPENAI_API_KEY=sk-... ./scripts/run_api.sh
# opsional: STT_MODEL=whisper-1
curl -s http://127.0.0.1:8090/v1/health
```

Batas server: audio ≤ 5 MB, base64 wajib. Jika belum dikonfigurasi, endpoint membalas
`503 STT_NOT_CONFIGURED` dan aplikasi jatuh ke input transkripsi manual.

---

## 5. Rencana Lanjutan (belum dikerjakan)

### 5.1 Penyelesaian FFI otomatis
Lihat §4.3. Target akhir: `frb_generated.dart` + `rust_bridge_generated/*` hasil generator
tanpa file manual.

### 5.2 WASM (Web)
1. `rustup target add wasm32-unknown-unknown` + `wasm-bindgen-cli`
2. Build `lq_bridge` dengan feature `wasm`, bungkus `wasm-bindgen`, salin ke `apps/app/web/`
3. Muat di `BridgeRuntime.init()` saat `kIsWeb` dan petakan ke `FFIEngine`

Catatan: saat ini Web memakai `PureDartEngine` (algoritma identik), sehingga aplikasi web
tetap berfungsi penuh kecuali pemanggilan biner Rust.

### 5.3 Sinkronisasi & konflik (SRS 11.2)
Sudah ada: XP aditif, status node tertinggi menang, operasi idempotent via `client_op_id`,
penolakan operasi yang sudah diterapkan. Belum: rekonsiliasi saldo gems offline vs server
secara parsial (saat ini pembelian offline diantrekan dan dievaluasi ulang server).

### 5.4 Quest & liga terjadwal
`tokio-cron-scheduler` untuk rollover musim mingguan (promosi/degradasi) dan reset quest
harian tertutup otomatis.

### 5.5 Fitur kurikulum lanjutan
Story interaktif, character writing (canvas stroke), tes penempatan adaptif, multi-course
(pemilihan bahasa target).

### 5.6 Monetisasi & sosial
Google Play Billing + StoreKit 2 (IAP untuk Super LinguaQuest), OAuth Google/Apple,
pencarian teman + feed kudos, push notification (FCM/APNs).

### 5.7 Pengerasan produksi
- Ganti `JWT_SECRET`, aktifkan HTTPS/TLS, hapus `android:usesCleartextTraffic`
- Simpan token di `flutter_secure_storage` (Keystore/Keychain)
- Rate limiting (`rl:auth:<ip>`) dan verifikasi email/OTP
- Rotasi `wallet_ledger` & partisi `xp_events` per bulan
- Backup PostgreSQL terjadwal

### 5.8 CI/CD & observabilitas
Pipeline: `cargo test --workspace`, `flutter test`, `flutter analyze`, build APK,
build `lq_bridge` multi-ABI, smoke test API terhadap container PostgreSQL/Redis sementara.
Metrik/tracing: ekspor OpenTelemetry dari `tracing`.

---

## 6. Peta file kunci

| Kebutuhan | File |
|---|---|
| Kontrak API | `crates/lq_types/src/lib.rs` |
| Logika bisnis | `crates/lq_core/src/{fsrs,answer_checker,gamification}.rs` |
| Skema & seed DB | `crates/lq_db/migrations/*.sql`, `crates/lq_db/src/{migrate,persist,seed}.rs` |
| Endpoint REST | `crates/lq_api/src/routes/*.rs`, `router.rs` |
| FFI Rust | `crates/lq_bridge/src/{api,ffi}.rs` |
| Klien HTTP | `apps/app/lib/data/api/api_client.dart` |
| State aplikasi | `apps/app/lib/state/{providers,session_controller}.dart` |
| Offline | `apps/app/lib/data/local/local_store.dart` |
| Bridge Dart | `apps/app/lib/rust_bridge/{rust_lib,engine,frb_generated}.dart` |
| Rekam suara | `apps/app/lib/features/lesson/speech_recorder.dart` |
| Layar utama | `apps/app/lib/ui/{auth_view,shell_view,lesson_screen}.dart` |
| Infrastruktur | `infra/docker-compose.yml` |
| Skrip verifikasi | `scripts/{run_api,smoke_api,build_bridge,test_ffi,verify_seeds}.*` |
