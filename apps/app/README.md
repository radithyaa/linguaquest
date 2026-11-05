# LinguaQuest — Klien Flutter

Klien multiplatform untuk server Rust `lq_api`. Semua data berasal dari API
(tidak ada data mock) dengan dukungan offline terbatas (cache kurikulum + antrean
sinkronisasi di SQLite).

## Menjalankan

```bash
flutter pub get

# URL server ditentukan lewat --dart-define (lihat lib/data/api/api_config.dart)
flutter run -d linux  --dart-define=API_BASE_URL=http://127.0.0.1:8090/v1
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8090/v1

# Android emulator: default http://10.0.2.2:8090/v1
# Android perangkat fisik:
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8090/v1
```

Akun demo: `demo@linguaquest.app` / `demo12345`.

## Engine Rust (FFI)

`lib/rust_bridge/` memuat `liblq_bridge.so` (Android `jniLibs`, Linux `linux/lib`).
Bangun library native dari root repo:

```bash
./scripts/build_bridge.sh          # semua ABI Android + Linux
```

Bila library tidak tersedia, aplikasi memakai `PureDartEngine` (porting Dart yang
identik) — terlihat pada badge/console `engine`.

## Struktur

| Folder | Isi |
|---|---|
| `lib/core` | Tema, warna brand, `TactileButton`, `MascotWidget`, `StatBadge` |
| `lib/data/api` | `ApiClient`, DTO (`models.dart`), `api_config.dart` |
| `lib/data/local` | `LocalStore` (SQLite: sesi, cache kurikulum, antrean offline) |
| `lib/state` | Provider Riverpod & `SessionController` |
| `lib/features` | Learn, Practice, Quests, League, Shop, Profile, Admin, Lesson (rekam suara) |
| `lib/ui` | `AuthView`, `AppShell`, `LessonScreen`, helper label |
| `test/` | Unit test engine/API-client + widget test |

## Pengujian

```bash
flutter analyze
flutter test
```
