# LinguaQuest (Monorepo Flutter & Rust)

Aplikasi pembelajaran bahasa bergamifikasi lintas platform (Android, iOS, Web, Desktop)
yang sekarang **sepenuhnya terhubung ke server Rust + PostgreSQL 16 + Redis 7**.
Seluruh data/state mock telah dihapus: kurikulum, progres, XP, gems, hearts, kartu FSRS,
quest, liga, dan toko berasal dari API `lq_api`.

Dokumen status lengkap: [`docs/INTEGRATION_STATUS.md`](docs/INTEGRATION_STATUS.md)

---

## 1. Arsitektur

```text
apps/app (Flutter)  ──HTTP/JSON──▶  crates/lq_api (Axum)  ──▶  PostgreSQL 16
        │                                   │                   Redis 7 (ZSET/leaderboard)
        │                                   └──▶ crates/lq_core (logika bisnis, dipakai ulang)
        │
        └──FFI (liblq_bridge.so)──▶ crates/lq_bridge  ──▶  crates/lq_core
```

```text
linguaquest/
├── apps/app/                       # Klien Flutter (Android/iOS/Web/Desktop)
│   ├── lib/
│   │   ├── core/                   # Design system (colors, TactileButton, Mascot, StatBadge)
│   │   ├── data/
│   │   │   ├── api/                # ApiClient (HTTP), models DTO, konfigurasi server
│   │   │   ├── local/              # SQLite lokal: sesi, cache kurikulum, antrean offline
│   │   │   └── models/             # Model domain klien
│   │   ├── features/               # Learn, Practice, Quests, League, Shop, Profile, Admin, Lesson
│   │   ├── rust_bridge/            # FFI ke lq_core (engine.dart, rust_lib.dart, frb_generated.dart)
│   │   ├── state/                  # Riverpod providers + SessionController
│   │   ├── ui/                     # AuthView, AppShell, LessonScreen, labels
│   │   └── main.dart
│   ├── android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/liblq_bridge.so
│   ├── linux/lib/liblq_bridge.so
│   └── test/                       # Unit & widget test
├── crates/
│   ├── lq_types/                   # DTO kontrak API (camelCase untuk Dart)
│   ├── lq_core/                    # FSRS 4.5, answer checker, gamifikasi
│   ├── lq_bridge/                  # C-FFI/WASM bridge + ekspor JSON C-ABI
│   ├── lq_db/                      # Domain state, repository, migrasi PostgreSQL, seed
│   └── lq_api/                     # Server Axum (REST /v1)
├── infra/docker-compose.yml        # PostgreSQL 16 + Redis 7
├── scripts/                        # run_api.sh, smoke_api.py, build_bridge.sh, test_ffi.sh, verify_seeds.py
└── docs/                           # SRS, CHECKLIST, INTEGRATION_STATUS, implementation_plan
```

---

## 2. Menjalankan (Development)

### A. Prasyarat
- Rust (stable) + `cargo`
- Flutter 3.24+ (`flutter doctor` bersih untuk target yang dipakai)
- Docker + Docker Compose
- (Android) Android SDK + NDK 27, `ANDROID_SDK_ROOT` diset

### B. Database & cache

```bash
docker compose -f infra/docker-compose.yml up -d
docker ps --filter name=linguaquest        # postgres:5433, redis:6380
```

Port sengaja digeser (PostgreSQL `5433`, Redis `6380`) agar tidak bentrok dengan layanan lain.
Migrasi & seed dijalankan otomatis oleh server saat start (idempotent, tercatat di tabel
`_lq_migrations`).

### C. Server API

```bash
cargo run -p lq_api            # atau: ./scripts/run_api.sh
curl http://127.0.0.1:8090/v1/health
```

Variabel lingkungan (opsional):

| Variabel | Default | Keterangan |
|---|---|---|
| `DATABASE_URL` | `postgres://linguaquest:linguaquest@127.0.0.1:5433/linguaquest` | jika gagal → mode in-memory |
| `REDIS_URL` | `redis://127.0.0.1:6380` | leaderboard ZSET; boleh kosong |
| `JWT_SECRET` | dev secret | **wajib diganti di produksi** |
| `PORT` / `HOST` | `8090` / `0.0.0.0` | alamat listen |
| `LQ_DEMO_DATA` | `0` | `1` = isi peserta contoh liga |
| `STT_PROVIDER` | `none` | `whisper` mengaktifkan `/v1/stt/transcribe` |
| `OPENAI_API_KEY` | – | wajib jika `STT_PROVIDER=whisper` |

Akun demo: **demo@linguaquest.app / demo12345** (dibuat otomatis saat startup).

### D. Aplikasi Flutter

```bash
cd apps/app
flutter pub get
flutter run -d linux          # desktop Linux
flutter run -d chrome         # web (API default 127.0.0.1:8090)
```

**Android** — perangkat fisik membutuhkan IP LAN mesin Anda:

```bash
flutter run -d <device> --dart-define=API_BASE_URL=http://192.168.1.10:8090/v1
# Emulator Android memakai otomatis http://10.0.2.2:8090/v1
```

Library native Rust untuk Android dibangun dengan:

```bash
./scripts/build_bridge.sh          # semua ABI Android + Linux desktop
./scripts/build_bridge.sh android  # hanya Android
```

### E. Verifikasi

```bash
cargo test --workspace          # 33+ tes Rust (core, db, api, bridge)
cd apps/app && flutter test     # 16 tes Flutter
python3 scripts/smoke_api.py    # alur API end-to-end
./scripts/test_ffi.sh           # Dart ⇄ Rust lewat liblq_bridge.so
python3 scripts/verify_seeds.py # seed SQL == seed Rust
```

---

## 3. Catatan penting

- **Token autentikasi** disimpan di SQLite lokal (scope aplikasi) beserta refresh token.
  Pertimbangkan `flutter_secure_storage`/Keystore untuk produksi.
- **Mode demo in-memory**: bila PostgreSQL tidak dapat dihubungi, server tetap berjalan
  dengan data seed di memori (data hilang saat restart). Status ini terlihat pada
  `GET /v1/health` (`"database":"memory"`) dan badge koneksi di aplikasi.
- **Cleartext HTTP** diizinkan pada manifest Android hanya untuk server pengembangan.
