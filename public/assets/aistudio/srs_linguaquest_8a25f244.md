# SRS: LinguaQuest (nama kode)

**Aplikasi Pembelajaran Bergamifikasi Lintas Platform (Android, iOS, Web, Windows, macOS, Linux)**

**Versi:** 1.0 | **Tanggal:** 5 November 2026 | **Status:** Final Draft / Ready for Development Review  
**Penulis Utama:** Product & Systems Architecture Team

---

## 1. Pendahuluan

### 1.1 Tujuan

Dokumen Spesifikasi Kebutuhan Perangkat Lunak (SRS) ini mendefinisikan kebutuhan fungsional dan non-fungsional, arsitektur sistem, skema basis data, rute navigasi, aturan bisnis gamifikasi, serta panduan implementasi teknis untuk aplikasi **LinguaQuest**. Dokumen ini ditujukan bagi tim rekayasa perangkat lunak (Flutter & Rust), desainer UI/UX, tim QA, serta pemangku kepentingan produk.

### 1.2 Ruang Lingkup

- **Aplikasi Klien:** Aplikasi Flutter tunggal yang mendukung 6 platform (Android, iOS, Web, Windows, macOS, Linux) dengan antarmuka responsif dan perilaku *offline-first*.
- **Modul Core Bersama (`lq_core`):** Pustaka Rust yang dapat dikompilasi ke pustaka *native* (FFI) dan WebAssembly (WASM) untuk menangani logika penilaian, algoritma FSRS, perhitungan XP, kelola *streak*, dan sinkronisasi secara konsisten di klien dan backend.
- **Backend Service:** *Modular monolith* berbasis Rust (axum), PostgreSQL 16, Redis 7, dan penyimpanan objek S3/R2.
- **Panel CMS/Admin:** Antarmuka berbasis web untuk pengelolaan kurikulum, otomatisasi audio TTS, pemantauan metrik, moderasi laporan, dan manajemen eksperimen A/B.
- **Batasan (Di Luar Lingkup v1):** Sesi video interaktif dengan tutor, marketplace konten pihak ketiga, fitur *Augmented Reality* (AR), dan percakapan bebas berbasis AI tanpa batasan modul.

### 1.3 Definisi dan Istilah

| Istilah | Keterangan |
| --- | --- |
| **Course** | Kurikulum pembelajaran untuk pasangan bahasa tertentu (contoh: Bahasa Inggris untuk penutur Bahasa Indonesia). |
| **Unit** | Kelompok topik utama dalam satu *Course* yang berisi beberapa *Node*. |
| **Node / Lesson** | Titik spesifik pada jalur belajar yang mewakili satu sesi materi atau latihan (terdiri dari 8–15 *Exercise*). |
| **Exercise** | Satuan soal/latihan interaktif dengan tipe bervariasi (pilihan ganda, menyusun kata, ketik suara, dll.). |
| **XP (Experience Points)** | Poin hadiah yang didapatkan setelah menyelesaikan latihan atau aktivitas pembelajaran. |
| **Streak** | Jumlah hari berturut-turut pengguna mencapai target pembelajaran harian. |
| **Hearts** | Batas toleransi kesalahan belajar; jika habis, pengguna perlu menunggu regenerasi, berlatih ulang, atau menggunakan Gems/Premium. |
| **Gems** | Mata uang virtual di dalam aplikasi untuk membeli item toko (*Streak Freeze*, *Heart Refill*, kosmetik). |
| **League** | Sistem kompetisi mingguan yang mengelompokkan 30 pengguna dalam tier tertentu berdasarkan perolehan XP. |
| **FSRS** | *Free Spaced Repetition Scheduler*, algoritma penjadwalan ulasan kosakata berbasis daya ingat ilmiah. |

### 1.4 Referensi

1. *Free Spaced Repetition Scheduler (FSRS) Specification v4.5*.
2. *RFC 9457: Problem Details for HTTP APIs*.
3. *OAuth 2.0 and OpenID Connect Core Specification*.
4. *Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP)*.
5. *General Data Protection Regulation (GDPR) Guidelines*.

---

## 2. Deskripsi Umum

### 2.1 Persona Pengguna

| Persona | Deskripsi & Karakteristik | Kebutuhan Utama |
| --- | --- | --- |
| **Pelajar Pemula** | Usia 18–25 tahun, terbiasa dengan aplikasi seluler, menyukai elemen permainan. | Durasi belajar singkat (5–15 menit/hari), visual menarik, dorongan sosial via *Streak* dan *League*. |
| **Profesional Sibuk** | Usia 26–40 tahun, bermobilitas tinggi, sering belajar saat komut atau waktu luang. | Fitur *offline-first*, notifikasi fleksibel, pengalaman *mobile-first* yang mulus. |
| **Desktop User** | Mahasiswa/pekerja yang menggunakan laptop/PC untuk belajar secara intensif. | Antarmuka layar lebar, dukungan navigasi papan ketik (*keyboard shortcuts*), sinkronisasi cepat antar perangkat. |
| **Kontributor / Editor** | Penyusun materi kurikulum dan pembuat konten bahasa. | Panel CMS yang responsif, pembuatan soal yang fleksibel, pembuatan audio otomatis via TTS. |
| **Admin Operasional** | Tim pendukung dan pengelola sistem aplikasi. | Fitur moderasi laporan, manajemen akun, dasbor analitik real-time, pengolahan *Feature Flag*. |

### 2.2 Arsitektur Sistem dan Matriks Platform Target

```
+-----------------------------------------------------------------------+
|              KLIEN FLUTTER (Android / iOS / Web / Desktop)            |
|  UI Component Layer | Riverpod 2 State | go_router | Drift (SQLite)   |
| --------------------------------------------------------------------- |
|            flutter_rust_bridge (FFI Native / WASM Web)                |
|  lq_core (Rust): FSRS Engine, Answer Checker, XP & Streak Calculator  |
+-----------------------------------|-----------------------------------+
                                    | HTTPS REST / WebSocket
                          Cloudflare CDN & WAF
                                    |
+-----------------------------------v-----------------------------------+
|                     API GATEWAY / BACKEND (Axum)                      |
|  auth | content | learning | gamification | social | shop | admin     |
+-------------+---------------------+--------------------+--------------+
              |                     |                    |
       PostgreSQL 16             Redis 7              S3 / R2
    (Primary & Replica)   (Leaderboard & Cache)     (Media Storage)
              |
       Worker (Rust Background Jobs: Weekly League, Push Notifications)
```

| Platform | Target OS Minimum | Format Distribusi | Catatan Implementasi / Integrasi Native |
| --- | --- | --- | --- |
| **Android** | API 24 (Android 7.0)+ | Android App Bundle (AAB) | Play Billing, Google Sign-In, FCM Push Notification. |
| **iOS** | iOS 15.0+ | IPA / App Store | StoreKit 2, Sign in with Apple (wajib), APNs Push. |
| **Web** | Chrome/Edge/Safari/Firefox (2 v-terakhir) | PWA (CanvasKit / WASM) | SQLite WASM + OPFS, Rust compiled to `wasm32-unknown-unknown`. |
| **Windows** | Windows 10 (1809)+ | MSIX / Installer | Native C++ runner, system tray, keyboard accelerators. |
| **macOS** | macOS 12.0 (Monterey)+ | Notarized DMG / App Store | Cocoa Integration, Menubar support. |
| **Linux** | Ubuntu 22.04 LTS+ | AppImage / `.deb` | GTK3 shell integration, SQLite native library. |

### 2.3 Asumsi dan Batasan

- **Audio Content:** Menggunakan mesin Text-to-Speech (TTS) berkualitas tinggi untuk draf otomatis dan rekaman penutur asli untuk revisi final.
- **Speech Processing:** Pengenalan suara (Speech-to-Text) diproses via backend gateway menggunakan *cloud API* (mis. OpenAI Whisper / Google Speech API) dengan *fallback* lokal di perangkat jika didukung API platform.
- **Kepatuhan Privasi:** Mengikuti ketentuan UU PDP (Indonesia) dan GDPR. Pengguna berusia di bawah 13 tahun dibatasi atau wajib verifikasi orang tua.
- **Konektivitas:** Aplikasi beroperasi secara penuh dalam mode luring (*offline*) untuk konten yang telah diunduh, dengan mekanisme antrean sinkronisasi *eventual consistency*.

---

## 3. Arsitektur dan Tech Stack

### 3.1 Stack Klien (Flutter)

- **Framework:** Flutter Stable Channel (Dart 3).
- **State Management:** `flutter_riverpod` v2 + `riverpod_generator`.
- **Routing:** `go_router` dengan dukungan *shell route*, *deep linking*, dan *navigation guard*.
- **Data Persistence:** `drift` (SQLite ORM) untuk penyimpanan lokal; `sqlite3_flutter_libs` pada desktop/mobile, serta `sqlite3 WASM` + `OPFS/IndexedDB` pada platform Web.
- **Rust FFI Integration:** `flutter_rust_bridge` v2 untuk menjembatani Dart dan Rust `lq_core`.
- **Audio & Media:** `just_audio` (playback), `record` (audio capture), `rive` (maskot & reaksi animasi), `lottie` (efek perayaan).
- **Network & API:** `dio` dengan adaptor pembatas jaringan, `flutter_secure_storage` untuk token sensitif.
- **Pengujian & Monitoring:** `flutter_test`, `golden_toolkit`, `patrol` (integration testing), `sentry_flutter` (crash report), dan `posthog_flutter` (analitik).

### 3.2 Stack Backend (Rust)

- **Framework:** `axum` 0.8 dengan `tokio` runtime dan middleware `tower-http` (kompresi, tracing, CORS, rate-limiting).
- **Database & Migration:** `sqlx` 0.8 dengan fitur *compile-time query verification* terhubung ke PostgreSQL 16.
- **Cache & Message Broker:** `redis-rs` / `deadpool-redis` (Redis 7) memanfaatkan Redis Streams untuk *event-driven architecture* dan Redis ZSET untuk *leaderboard* real-time.
- **Keamanan & Auth:** `argon2` (argon2id) untuk pemrosesan kata sandi, `jsonwebtoken` (EdDSA / ES256) untuk JWT auth.
- **Dokumentasi API:** `utoipa` OpenAPI 3.1 generator.
- **Worker/Scheduler:** `tokio-cron-scheduler` untuk tugas terencana harian/mingguan.

### 3.3 Integrasi Flutter dan Rust (`lq_core`)

1. **Target Native (Mobile & Desktop):** Pustaka Rust `lq_core` dikompilasi menjadi pustaka statis/dinamis (`.so`, `.dylib`, `.dll`, `.a`). `flutter_rust_bridge` menghasilkan *bindings* Dart C-FFI berkinerja tinggi tanpa penundaan *serialization overhead*.
2. **Target Web:** `lq_core` dikompilasi menggunakan target `wasm32-unknown-unknown` dan dibungkus dengan `wasm-bindgen`. Modul dimuat secara asinkron di Web Worker agar tidak memblokir Utamanya UI Thread (Main Thread).
3. **Fungsi Utama `lq_core`:**
   - Evaluasi teks jawaban (normalisasi Unicode NFKD, pembersihan tanda baca, penghitungan jarak Levenshtein untuk toleransi typo).
   - Algoritma FSRS 4.5 (perhitungan interval, *stability*, *difficulty*, dan *retrievability*).
   - Perhitungan poin XP, penentuan status *streak*, serta pembaruan masa berlaku *Heart*.
   - Pemvalidasi struktur data dan penandatangan *payload* transaksi offline.

```
[User Input] --> [Flutter UI] --> [flutter_rust_bridge / WASM]
                                       |
                                       v
                             [lq_core (Rust Engine)]
                                       |
                   +-------------------+-------------------+
                   |                                       |
        [Validasi Jawaban Instant]               [Penjadwalan FSRS]
                   |                                       |
                   +-------------------+-------------------+
                                       |
                                       v
                            [Kembalikan Hasil Ke UI]
                                       &
                        [Simpan Operasi ke Local Drift DB]
```

---

## 4. Struktur Repositori (Monorepo)

```
linguaquest/
├── apps/
│   ├── app/                      # Aplikasi Klien Utama Flutter (Mobile, Web, Desktop)
│   │   ├── lib/
│   │   │   ├── core/             # Theme, Network, Router, DI, Utils
│   │   │   ├── features/         # Auth, Onboarding, Learn, Lesson, Quests, League, Social, Shop, Profile
│   │   │   ├── data/             # Drift DB, Repositories, OpenAPI Dio Client, Sync Engine
│   │   │   └── l10n/             # File ARB Lokalisasi (i18n)
│   │   └── rust_bridge/          # Dart generated bindings dari flutter_rust_bridge
│   └── admin/                    # Flutter Web Admin & Content Management System (CMS)
├── crates/
│   ├── lq_core/                  # Shared Business Logic Engine (Rust: Native + WASM)
│   ├── lq_api/                   # Backend Server Gateway (Axum HTTP & WS Server)
│   ├── lq_worker/                # Background Job Processing & Queue Consumers
│   ├── lq_db/                    # Sqlx Database Entities, Repositories, Migrations
│   └── lq_types/                 # Shared DTOs, API Contracts, & Utoipa Schemas
├── infra/                        # Dockerfiles, Kubernetes Manifests, Terraform Scripts
├── docs/                         # OpenAPI Specifications, Architecture Diagrams, Manuals
└── .github/workflows/            # CI/CD Pipelines (Build, Test, Release)
```

---

## 5. Kebutuhan Fungsional

*Prioritas:* **M** = Must Have (MVP), **S** = Should Have, **C** = Could Have.

### 5.1 Autentikasi dan Manajemen Akun (AUTH)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **AUTH-01** | Registrasi Email | Pengguna dapat mendaftar dengan email dan password. Password dienkripsi dengan Argon2id. | **M** |
| **AUTH-02** | OAuth 2.0 / SSO | Integrasi login Google & Apple (wajib untuk iOS sesuai panduan App Store). | **M** |
| **AUTH-03** | Email Verification & Reset | Pengiriman token sekali pakai (OTP/Link) via email untuk verifikasi dan lupa password. | **M** |
| **AUTH-04** | Mode Guest / Anonim | Pengguna dapat langsung mencoba latihan tanpa mendaftar. Data lokal dimigrasikan saat registrasi. | **M** |
| **AUTH-05** | Sesi Multi-Perangkat | Pengguna dapat melihat daftar perangkat aktif dan melakukan registrasi logout jarak jauh. | **S** |
| **AUTH-06** | Hapus & Ekspor Data | Pemenuhan hak UU PDP/GDPR: pengguna dapat mengunduh arsip data atau menghapus akun permanen. | **M** |

### 5.2 Onboarding (ONB)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **ONB-01** | Pemilihan Bahasa | Pengguna memilih bahasa asal (UI) dan bahasa sasaran (Target Course). | **M** |
| **ONB-02** | Penetapan Target Harian | Pengguna memilih komitmen belajar harian (Santai: 10 XP, Biasa: 20 XP, Serius: 30 XP, Intensif: 50 XP). | **M** |
| **ONB-03** | Tes Penempatan Adaptif | Tes adaptif untuk menentukan titik awal pengguna pada jalur kurikulum jika sudah memiliki dasar. | **S** |
| **ONB-04** | Pengaturan Pengingat | Meminta izin notifikasi dan menetapkan waktu pengingat harian. | **M** |

### 5.3 Kurikulum dan Jalur Belajar (CUR)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **CUR-01** | Struktur Kurikulum | Struktur data berjenjang: *Course* $\rightarrow$ *Unit* $\rightarrow$ *Node* $\rightarrow$ *Lesson* $\rightarrow$ *Exercise*. | **M** |
| **CUR-02** | Peta Belajar Visual | Jalur belajar vertikal interaktif dengan indikator status *Node*: Terkunci, Aktif, Selesai, atau Emas (*Mastered*). | **M** |
| **CUR-03** | Tipe Node Variatif | Jalur mendukung tipe node: Pelajaran Standar, Ulasan Kosakata, Cerita Interaktif, dan *Checkpoint*. | **M** |
| **CUR-04** | Pembukaan Node | Node terbuka berurutan. Pengguna dapat melompati unit dengan lulus *Unit Jump-Test*. | **S** |
| **CUR-05** | Multi-Course Management| Pengguna dapat mendaftar dan beralih antar beberapa *Course* secara fleksibel. | **M** |
| **CUR-06** | Unit Guidebook | Menyediakan ringkasan tata bahasa, frasa kunci, dan tips budaya di awal setiap Unit. | **S** |

### 5.4 Tipe Latihan / Exercise (EXE)

| ID | Tipe Exercise | Deskripsi Logika Penilaian | Prioritas |
| --- | --- | --- | --- |
| **EXE-01** | Multiple Choice | Memilih 1 dari 4 opsi jawaban (teks atau gambar). | **M** |
| **EXE-02** | Word Bank Build | Menyusun kata-kata acak menjadi kalimat terjemahan yang benar. | **M** |
| **EXE-03** | Typing Translation | Mengetik terjemahan secara manual dengan toleransi typo (Levenshtein Distance $\le 2$). | **M** |
| **EXE-04** | Audio Listening | Mendengarkan rekaman audio lalu mengetik frasa atau memilih opsi yang sesuai. | **M** |
| **EXE-05** | Pair Matching | Mencocokkan 5 pasangan kata/frasa dalam dua kolom. | **M** |
| **EXE-06** | Fill in the Blank | Mengisi bagian kata yang hilang dalam suatu kalimat berdasarkan konteks. | **S** |
| **EXE-07** | Speech Pronunciation | Pengguna mengucapkan kalimat; backend STT menilai akurasi pelafalan. | **S** |
| **EXE-08** | Interactive Story | Membaca/mendengarkan dialog cerita interaktif disertai pertanyaan pemahaman. | **S** |
| **EXE-09** | Character Writing | Latihan mengarang/menulis karakter aksara non-Latin (mis. Kanji/Hanzi/Kana) stroke-by-stroke. | **C** |

### 5.5 Sesi Pelajaran (LES)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **LES-01** | Pelaksanaan Pelajaran | Sesi terdiri atas 8–15 soal. Progress bar memperlihatkan capaian real-time. | **M** |
| **LES-02** | Queue Soal Salah | Soal yang dijawab salah diulang kembali secara otomatis di akhir sesi hingga dijawab benar. | **M** |
| **LES-03** | Combo & Bonus XP | Jawab benar berturut-turut memberikan efek efek visual combo dan bonus XP tambahan. | **M** |
| **LES-04** | Heart Deduction | Kesalahan mengurangi 1 Heart. Jika Heart habis, sesi dihentikan kecuali pengguna mengisi ulang. | **M** |
| **LES-05** | Layar Rangkuman | Menampilkan perolehan XP, persentase akurasi, waktu penyelesaian, dan perkembangan Streak. | **M** |
| **LES-06** | Aksesibilitas UI | Mendukung kontras tinggi, navigasi papan ketik lengkap, dan pembaca layar (*Screen Reader*). | **M** |

### 5.6 Gamifikasi dan Logika Bisnis (GAM)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **GAM-01** | Perhitungan XP | Pemberian XP transparan berdasarkan jenis aktivitas dan combo (Detail di Bab 9.1). | **M** |
| **GAM-02** | Sistem Streak | Mempertahankan hari belajar beruntun. Mendukung fitur *Streak Freeze* dan *Streak Repair*. | **M** |
| **GAM-03** | Mekanisme Hearts | Maksimal 5 Hearts. Regenerasi otomatis 1 Heart setiap 4 jam, atau isi instan via Gems/Praktik. | **M** |
| **GAM-04** | Ekonomi Gems | Mata uang virtual didapatkan dari *Streak milestone*, pencapaian *Quest*, atau promosi Liga. | **M** |
| **GAM-05** | Sistem Liga (Weekly) | 30 pengguna dikelompokkan dalam satu grup. Top 5 promosi tier, Bottom 5 degradasi. | **S** |
| **GAM-06** | Daily & Monthly Quests| 3 tantangan harian opsional yang diacak setiap hari dan 1 pencapaian lencana bulanan. | **S** |
| **GAM-07** | Achievement Badges | Sistem lencana pencapaian berjenjang (Bronze, Silver, Gold, Diamond). | **S** |
| **GAM-08** | Maskot Beranimasi | Maskot interaktif (Rive) yang memberikan reaksi emosional kontekstual saat pengguna menjawab. | **S** |

### 5.7 Sistem Ulasan Berulang / SRS (REV)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **REV-01** | Hub Latihan Mandiri | Area khusus untuk mengulas kata-kata yang sulit atau memperbaiki kesalahan lampau. | **S** |
| **REV-02** | Algoritma FSRS 4.5 | Kartu kata diulas dengan 4 tombol respons (*Again*, *Hard*, *Good*, *Easy*) untuk menghitung interval ulasan berikutnya. | **S** |
| **REV-03** | Kamus Kosakata | Daftar seluruh kata yang telah dipelajari beserta tingkat daya ingat (*retrievability*). | **S** |

### 5.8 Fitur Sosial (SOC)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **SOC-01** | Sistem Pertemanan | Cari pengguna via username/QR code, kirim permintaan pertemanan, dan undang teman. | **S** |
| **SOC-02** | Social Activity Feed | Lini masa aktivitas teman (mis. pencapaian streak 30 hari) dengan tombol kirim *Kudos*. | **C** |
| **SOC-03** | Profil Publik | Menampilkan statistik total XP, liga saat ini, lencana, dan daftar kata dikuasai. | **S** |
| **SOC-04** | Keamanan Sosial | Fitur memblokir dan melaporkan pengguna yang tidak pantas. | **S** |

### 5.9 Toko dan Monetisasi (SHOP)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **SHOP-01** | Pembelian dengan Gems | Penukaran Gems untuk *Streak Freeze*, *Heart Refill*, dan kustomisasi busana maskot. | **S** |
| **SHOP-02** | Langganan Premium | Pembelian akun Premium (Hearts tak terbatas, bebas iklan, ulasan FSRS tak terbatas). | **S** |
| **SHOP-03** | Integrasi IAP & Web | Pembelian via Google Play Billing, Apple StoreKit 2, atau Gateway Checkout Web (Stripe/Midtrans). | **S** |

### 5.10 Notifikasi (NTF)

- **Push Notifications:** Pengingat harian cerdas (disesuaikan dengan jam belajar tersering pengguna), notifikasi pertarungan Liga menjelang penutupan mingguan, serta pemberitahuan pertemanan.
- **Local Notifications:** Pengingat berbasis jam perangkat tanpa tergantung koneksi server.

### 5.11 Fitur Offline dan Sinkronisasi (OFF)

| ID | Kebutuhan Fungsional | Deskripsi | Prioritas |
| --- | --- | --- | --- |
| **OFF-01** | Unduh Konten Otomatis| Mengunduh 1 Unit aktif di depan (soal + aset audio) untuk ketersediaan luring. | **S** |
| **OFF-02** | Offline Progress Queue| Sesi yang diselesaikan secara offline disimpan di Drift DB lokal dan ditandai *un-synced*. | **M** |
| **OFF-03** | Auto-Sync Engine | Melakukan pendorongan (*push*) data transaksi saat koneksi kembali stabil. | **M** |

### 5.12 Admin dan CMS (ADM)

- **Content Editor:** Editor *WYSIWYG* dan *drag-and-drop* untuk membangun struktur *Unit*, *Node*, dan *Exercise*.
- **Audio Generator Integration:** Tombol pembuatan audio otomatis dari teks menggunakan mesin TTS cloud langsung ke S3.
- **Workflow Rilis:** Alur status konten: `Draft` $\rightarrow$ `Review` $\rightarrow$ `Published` (dengan penomoran versi kurikulum yang ketat).
- **Manajemen Pengguna & Moderasi:** Alat pencarian pengguna, penangguhan akun, dan penanganan laporan kesalahan soal dari pengguna.
- **Feature Flag & A/B Testing:** Konfigurasi dinamis untuk menguji variabel gamifikasi atau membuka fitur baru.

---

## 6. Rute Halaman (go_router)

### 6.1 Layout Adaptif

- **Layar Kecil (< 600 dp - Mobile):** Navigasi bawah (*Bottom Navigation Bar*) dengan 5 tab utama.
- **Layar Sedang (600 - 1024 dp - Tablet):** *Navigation Rail* di sisi kiri.
- **Layar Besar (> 1024 dp - Desktop/Web):** *Sidebar Navigation* tetap di sisi kiri, dipadukan dengan panel kanan (*Right Sidebar*) yang menampilkan widget *Streak*, *Quests*, dan *League*.
- **Sesi Pelajaran:** Sesi latihan berjalan dalam mode *Fullscreen Modal Shell* tanpa bilah navigasi utama untuk menjaga fokus pengguna.

### 6.2 Tabel Pemetaan Rute

| Path Rute | Nama Halaman | Otentikasi | Catatan Akses & Komponen |
| --- | --- | --- | --- |
| `/` | Initial Guard Route | Publik | Pengalihan otomatis ke `/learn` atau `/welcome`. |
| `/splash` | Splash Screen | Publik | Inisialisasi DB SQLite, muat modul WASM/FFI Rust. |
| `/welcome` | Landing / Welcome | Publik | Pilihan login atau langsung mencoba (mode guest). |
| `/onboarding/language` | Pilih Bahasa Target | Publik | Alur awal konfigurasi profil. |
| `/onboarding/reason` | Alasan Belajar | Publik | Pengumpulan metadata onboarding. |
| `/onboarding/goal` | Target Harian XP | Publik | Pilihan target 10–50 XP. |
| `/onboarding/placement` | Placement Test | Publik | Opsional (dapat dilewati). |
| `/onboarding/notifications`| Izin Notifikasi | Publik | Diabaikan pada platform desktop non-mobile. |
| `/auth/login` | Form Login | Publik | Form email/password & tombol OAuth SSO. |
| `/auth/register` | Form Registrasi | Publik | Konversi dari akun guest atau pendaftaran baru. |
| `/auth/forgot` | Lupa Password | Publik | Input email pengiriman token reset. |
| `/auth/reset` | Reset Password | Publik | Penanganan deep-link dengan query parameters `?token=`. |
| `/auth/verify` | Verifikasi Email | Publik | Penanganan deep-link verifikasi email. |
| `/learn` | Jalur Belajar Utama | User | Tab 1 (Main Dashboard Shell). |
| `/learn/unit/:unitId` | Detail & Guidebook Unit| User | Menampilkan teori tata bahasa dan daftar frasa. |
| `/lesson/:lessonId` | Sesi Pelajaran | User / Guest | Fullscreen Shell (No Navigation Bar). |
| `/lesson/:lessonId/result`| Rangkuman Pelajaran | User | Animasi perayaan perolehan XP dan Streak. |
| `/story/:storyId` | Cerita Interaktif | User | Mode narasi interaktif. |
| `/practice` | Hub Latihan | User | Tab 2 (Review Mistake & FSRS Cards). |
| `/practice/mistakes` | Ulang Kesalahan | User | Latihan khusus daftar soal yang pernah salah. |
| `/practice/flashcards` | Flashcards FSRS | User | Pelatihan kartu kata dengan algoritma FSRS. |
| `/practice/words` | Kamus Kosakata | User | List kata-kata yang telah dikuasai. |
| `/quests` | Tantangan & Quest | User | Tab 3 (Daily & Monthly Quests). |
| `/league` | Peringkat Liga | User | Tab 4 (Leaderboard Liga 30 Pengguna). |
| `/league/history` | Riwayat Liga | User | Catatan histori promosi/degradasi liga. |
| `/friends` | Daftar Pertemanan | User | Tab 5 (Social Feed & Friend List). |
| `/friends/add` | Tambah Teman | User | Pencarian pengguna & Scan QR Code. |
| `/invite/:code` | Terima Undangan | Publik | Universal deep-link rujukan pertemanan. |
| `/shop` | Toko Virtual | User | Pembelian items dengan Gems. |
| `/shop/premium` | Halaman Premium | User | Paywall & pilihan paket langganan. |
| `/profile` | Profil Pengguna | User | Statistik personal & pencapaian Badges. |
| `/profile/achievements` | Daftar Lencana | User | Rincian progres lencana pencapaian. |
| `/u/:username` | Profil Publik | User / Publik| Tampilan profil pengguna lain. |
| `/course/select` | Beralih Course | User | Pilihan menambah atau mengganti kurikulum bahasa. |
| `/downloads` | Manajemen Offline | User | Manajemen unduhan paket offline (Mobile/Desktop). |
| `/settings` | Pengaturan Umum | User | Pengaturan akun, notifikasi, dan privasi. |
| `/settings/account` | Pengaturan Akun | User | Ubah email, password, atau hapus akun. |
| `/settings/notifications`| Pengaturan Notifikasi| User | Sakelar granular waktu dan tipe push notification. |
| `/settings/privacy` | Privasi & Data | User | Opsi ekspor data pribadi (GDPR/UU PDP). |
| `/admin/login` | Login Admin | Admin | Halaman khusus portal CMS Admin. |
| `/admin/dashboard` | CMS Dashboard | Admin / Editor| Dasbor utama statistik & operasional. |
| `/admin/courses` | Kelola Kurikulum | Editor | Editor drag-and-drop jalur kurikulum. |
| `/admin/lessons/:id` | Editor Latihan | Editor | WYSIWYG editor pembuatan soal. |
| `/admin/users` | Manajemen Pengguna | Support/Admin| Pencarian dan aksi akun pengguna. |
| `/admin/experiments` | Feature Flags | Admin | Manajemen pengujian A/B dan feature toggle. |
| `/404` | Page Not Found | All | Halaman kustom fallback kesalahan navigasi. |

---

## 7. Desain Backend

### 7.1 Gaya Arsitektur

Backend menerapkan **Modular Monolith Architecture** menggunakan kerangka kerja Axum di mana kode dipisahkan secara ketat berdasarkan domain bisnis ke dalam *internal crates* atau modul Rust. Arsitektur ini memudahkan pengujian, mempercepat waktu kompilasi, serta memungkinkan pemisahan layanan menjadi *microservices* di masa depan tanpa perlu menulis ulang logika inti.

### 7.2 Struktur Modul Backend

- `auth`: Autentikasi JWT, manajemen sesi, hashing kata sandi Argon2id, dan OAuth2.
- `content`: Penyediaan struktur kurikulum, penanganan ETag cache, dan verifikasi versi kurikulum.
- `learning`: Pengelolaan sesi pelajaran, validasi jawaban sesi, dan penghitungan FSRS.
- `gamification`: Mesin XP, pembaruan *Streak*, logika koin *Gems*, *Hearts*, dan agregasi *League*.
- `social`: Pertemanan, aktivitas lini masa, dan pengiriman *kudos*.
- `shop`: Katalog item toko, transaksi ledger gems, dan verifikasi resi IAP (App Store / Play Store).
- `notify`: Layanan antrean push notification via FCM/APNs dan email pengingat.
- `sync`: Engine pemrosesan batch sinkronisasi offline berbasis transaksi deterministik.

### 7.3 Konvensi API dan Error Handling

- Seluruh endpoint API berikutan RESTful standar dengan *prefix* versi `/v1/`.
- Format Respons Kesalahan standar menggunakan **RFC 9457 Problem Details JSON**:

```json
{
  "type": "https://api.linguaquest.com/errors/insufficient-hearts",
  "title": "Hearts Depleted",
  "status": 403,
  "detail": "Anda tidak memiliki sisa Heart untuk memulai pelajaran ini.",
  "code": "HEARTS_EXHAUSTED",
  "timestamp": "2026-11-05T00:00:00Z"
}
```

### 7.4 Alur Penyelesaian Pelajaran (Complete Session Flow)

```
[Flutter Client]              [Axum Server]             [lq_core]           [PostgreSQL DB]
       |                            |                       |                      |
       |--- POST /sessions/start -->|                       |                      |
       |<-- Session ID + Nonce -----|                       |                      |
       |                            |                       |                      |
  (Menjawab Soal secara Lokal)      |                       |                      |
       |                            |                       |                      |
       |--- POST /sessions/complete>|                       |                      |
       |    (Payload + Answers)     |--- Verifikasi Sesi -->|                      |
       |                            |    & Uji Jawaban      |                      |
       |                            |<-- Hasil Akurasi -----|                      |
       |                            |                                              |
       |                            |==== Transaksi DB (Atomic Batch Update) =====>|
       |                            |  1. Tulis Record Session Attempt             |
       |                            |  2. Tambah XP Log & Update User Stats        |
       |                            |  3. Update Streak & Regenerasi Hearts        |
       |                            |  4. Tulis Ledger Transaksi Gems (jika ada)   |
       |                            |<=============================================|
       |                            |
       |<-- Response Summary -------| (Publish Event ke Redis Streams)
```

---

## 8. Desain Basis Data (PostgreSQL)

### 8.1 Data Definition Language (DDL) Utama

```sql
-- Ekstensi Wajib
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- 1. Pengguna dan Autentikasi
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username CITEXT UNIQUE NOT NULL,
    email CITEXT UNIQUE NOT NULL,
    password_hash TEXT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    locale VARCHAR(10) DEFAULT 'id',
    timezone VARCHAR(50) DEFAULT 'Asia/Jakarta',
    role VARCHAR(20) NOT NULL DEFAULT 'user',
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

-- 2. Kurikulum dan Konten
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_lang VARCHAR(10) NOT NULL,
    to_lang VARCHAR(10) NOT NULL,
    title VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    position INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    guidebook_json JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    position INT NOT NULL,
    kind VARCHAR(30) NOT NULL, -- lesson, review, story, checkpoint
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
    content_json JSONB NOT NULL,
    audio_url TEXT NULL,
    difficulty REAL DEFAULT 1.0
);

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
    freezes_available INT NOT NULL DEFAULT 0
);

CREATE TABLE xp_events (
    id BIGSERIAL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    source VARCHAR(50) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    local_date DATE NOT NULL,
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE lesson_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id),
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    accuracy REAL NOT NULL,
    xp_awarded INT NOT NULL,
    hearts_lost INT NOT NULL,
    duration_ms INT NOT NULL,
    client_op_id UUID UNIQUE NOT NULL
);

-- 4. FSRS Spaced Repetition System
CREATE TABLE srs_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id UUID NOT NULL,
    stability REAL NOT NULL DEFAULT 0.0,
    difficulty REAL NOT NULL DEFAULT 0.0,
    due_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_review TIMESTAMPTZ NULL,
    reps INT NOT NULL DEFAULT 0,
    lapses INT NOT NULL DEFAULT 0,
    CONSTRAINT uk_user_item UNIQUE(user_id, item_id)
);

-- 5. Kebijakan Ledger Transaksi Gems (Append-Only)
CREATE TABLE wallet_ledger (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delta INT NOT NULL, -- Positif (Penambahan), Negatif (Pengurangan)
    reason VARCHAR(50) NOT NULL,
    ref_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indeks Kinerja Inti
CREATE INDEX idx_xp_events_user_date ON xp_events(user_id, local_date);
CREATE INDEX idx_srs_cards_due ON srs_cards(user_id, due_at);
CREATE INDEX idx_exercises_lesson ON exercises(lesson_id);
```

### 8.2 Struktur Caching Redis

```
# Leaderboard Liga Real-Time (ZSET)
# Key Format: lb:league:{season_id}:{group_id}
# Score: XP Mingguan | Member: user_id
ZADD lb:league:2026-W45:group_8892 1450 "usr_01H8X..."

# Nonce dan State Sesi Pelajaran Aktif (Hash + TTL 1 Jam)
# Key: session:active:{session_id}
HSET session:active:ses_9921 user_id "usr_01H8X..." nonce "a8f9c1" hearts 5

# Rate Limiting (Counter + TTL 1 Menit)
# Key: rl:auth:{ip_address}
INCR rl:auth:192.168.1.1
```

---

## 9. Aturan Bisnis Gamifikasi Terperinci

### 9.1 Formula Kalkulasi Perolehan XP

XP perolehan dari penyelesaian satu sesi pelajaran dihitung menggunakan rumus:

$$\text{XP}_{\text{total}} = \text{XP}_{\text{base}} + \text{XP}_{\text{accuracy\_bonus}} + \text{XP}_{\text{combo\_bonus}}$$

Di mana ketentuannya adalah:
- $\text{XP}_{\text{base}} = 10 \text{ XP}$ (untuk penyelesaian sesi standar).
- $\text{XP}_{\text{accuracy\_bonus}}$:
  - Akurasi $100\% = +5 \text{ XP}$
  - Akurasi $90\% - 99\% = +3 \text{ XP}$
  - Akurasi $< 90\% = +0 \text{ XP}$
- $\text{XP}_{\text{combo\_bonus}} = \lfloor \frac{\text{Max Combo}}{5} \rfloor \times 2 \text{ XP}$ (maksimal bonus combo $= +6 \text{ XP}$).

### 9.2 Logika Sistem Streak & Timezone Adjustment

1. **Perhitungan Hari:** Batas pergantian hari ditentukan berdasarkan *zona waktu lokal* perangkat pengguna (`user_stats.timezone`). Hari dianggap aktif jika akumulasi XP harian ($\sum \text{XP}_{\text{local\_date}}$) $\ge$ Target Harian Pengguna.
2. **Streak Freeze:** Jika pengguna gagal mencapai target harian, sistem otomatis memeriksa ketersediaan `freezes_available`.
   - Jika `freezes_available > 0`: berkurang 1, status *Streak* tidak bertambah namun **tidak putus** (frozen).
   - Jika `freezes_available == 0`: *Streak* kembali ke 0.
3. **Streak Repair:** Pengguna dapat memulihkan streak yang putus dalam kurun 48 jam dengan membayar sejumlah Gems atau melalui langganan Premium.

### 9.3 Algoritma FSRS 4.5 (Spaced Repetition)

Algoritma FSRS memperhitungkan daya ingat berdasarkan parameter *Stability* ($S$) dan *Difficulty* ($D$). Pilihan jawaban menentukan tingkat daya ingat pengguna:

$$\text{Rating}: 1 = \text{Again}, 2 = \text{Hard}, 3 = \text{Good}, 4 = \text{Easy}$$

- **Retrievability ($R$):**
  $$R(t) = \left(1 + F \cdot \frac{t}{S}\right)^{-1}$$
  *Di mana $t$ adalah interval hari sejak ulasan terakhir, dan $F = \frac{19}{81}$.*
- Interval ulasan berikutnya dihitung saat $R(t)$ mencapai target akurasi (default: 90%).

### 9.4 Sistem Liga Mingguan (League Lifecycle)

1. **Struktur:** Terbagi menjadi 10 Tier (Bronze, Silver, Gold, Sapphire, Ruby, Emerald, Amethyst, Pearl, Obsidian, Diamond).
2. **Pengelompokan:** Setiap grup diisi maksimal 30 pengguna acak dalam tier yang sama.
3. **Jadwal Selesai:** Setiap hari Minggu pukul 23:59 UTC.
4. **Aturan Promosi & Degradasi:**
   - Rank 1–5: Promosi ke Tier lebih tinggi + Hadiah Gems.
   - Rank 6–25: Bertahan di Tier saat ini.
   - Rank 26–30: Degradasi ke Tier lebih rendah (tidak berlaku di Tier Bronze).

---

## 10. Antarmuka Pengguna & Desain Pengalaman (UI/UX)

### 10.1 Sistem Desain & Tema (Design System)

- **Warna Identitas Utama:**
  - Primary Green: `#58CC02` (Tombol Aksi Utama, Progres Belajar).
  - Secondary Blue: `#1CB0F6` (Elemen Fitur Latihan & FSRS).
  - Accent Orange: `#FF9600` (Streak & Api).
  - Danger Red: `#FF4B4B` (Errors, Heart Loss).
  - Neutral Dark: `#4B4B4B` (Teks Utama Light Theme).
- **Tipografi:** Dynamic Font scaling berbasis `Inter` untuk alfabet Latin dan `Noto Sans` untuk skrip non-Latin.
- **Micro-Interactions:** Setiap sentuhan tombol menyajikan umpan balik *haptic feedback* (pada perangkat seluler) dan efek animasi penekanan 3D (*3D-Button Press Effect*).

### 10.2 Responsivitas & Pengalaman Layar Lebar

```
+-------------------------------------------------------------------+
|  [Logo] Belajar  Latihan  Quest  Liga  Profil   [ 500 ] ( 5) (  ) |
+-------------------------------------------------------------------+
| Jalur Belajar Utama                     | Panel Statistik Kanan   |
|                                         | ----------------------- |
|     [ Unit 1: Dasar Bahasa ]            | Streak Harian           |
|         ( Node 1: Start )               |  [===  ] 5 Hari Aktif   |
|                |                        |                         |
|         ( Node 2: Frasa )               | Tantangan Harian        |
|                |                        |  [x] Selesaikan 1 Sesi  |
|         ( Node 3: Review )              |  [ ] Dapatkan 30 XP     |
|                                         |                         |
|     [ Unit 2: Percakapan ]              | Liga Minggu Ini         |
|         ( Node 4: Terkunci )            |  Rank #3 (Amethyst)     |
+-------------------------------------------------------------------+
```

---

## 11. Strategi Offline dan Sinkronisasi Data

### 11.1 Alur Kerja Offline-First

1. **Pre-fetching:** Klien secara aktif mengunduh paket data JSON untuk 1 Unit di depan beserta aset audio resolusi rendah saat terhubung ke Wi-Fi.
2. **Penyimpanan Lokal:** Kinerja pelajaran luring dieksekusi sepenuhnya melalui pustaka `lq_core` di mana rekaman transaksi dicatat pada database SQLite lokal (`Drift`).
3. **Antrean Operasi (Sync Queue):** Setiap aktivitas penyelesaian sesi menghasilkan *Operation Payload* unik dengan kunci UUID (`client_op_id`).

### 11.2 Resolusi Konflik (Conflict Resolution)

Perubahan state lokal dan server diselaraskan dengan aturan deterministik berikut:

- **XP & Total Poin:** Penggabungan bersifat aditif ($\text{XP}_{\text{Server}} = \text{XP}_{\text{Server}} + \sum \text{XP}_{\text{Offline\_Events}}$).
- **Progres Node:** Prinsip status tertinggi yang menang ($\text{Status}_{\text{Final}} = \max(\text{Status}_{\text{Local}}, \text{Status}_{\text{Server}})$).
- **Hearts & Gems Ledger:** Transaksi server menjadi *source of truth*. Transaksi offline yang menggunakan Gems berlebih dari saldo riil akan ditolak oleh server saat sinkronisasi (*rollback local state*).

---

## 12. Kebutuhan Non-Fungsional

### 12.1 Kinerja dan Efisiensi Perangkat (Performance)

- **UI Rendering:** Antarmuka Flutter wajib mempertahankan kecepatan *frame rate* konsisten **60 FPS** (120 FPS pada layar ProMotion) tanpa gejala *jank*.
- **Waktu Muat Aplikasi:** Cold start < 1.5 detik pada perangkat seluler kelas menengah.
- **Latency API:** Response time API Gateway p95 < 100 ms untuk transaksi non-upload.
- **Ukuran Aplikasi:** Ukuran unduhan awal APK/IPA < 35 MB.

### 12.2 Keamanan dan Privasi Data (Security)

- Enkripsi data saat transit menggunakan TLS 1.3.
- Data sensitif lokal (Auth Token) disimpan menggunakan `EncryptedSharedPreferences` (Android) dan `Keychain` (iOS).
- Pemasangan pembatas laju API (*Rate Limiting*) ketat untuk mencegah kejahatan *brute-force attack* (Maksimal 5 percobaan login gagal per menit per IP).
- Sanitasi data tingkat lanjut pada `lq_core` untuk mencegah serangan SQL Injection dan Cross-Site Scripting (XSS).

### 12.3 Keandalan dan Ketersediaan (Availability)

- Garansi ketersediaan backend service (*Uptime SLA*) sebesar **99.9%** (tidak mencakup periode pemeliharaan yang diumumkan).
- Penerapan strategi *Graceful Degradation*: jika Redis mengalami kendala, sistem beralih sementara ke penyimpanan database PostgreSQL untuk verifikasi auth.

---

## 13. Matriks Pengujian dan Penjaminan Mutu (QA)

| Kategori Pengujian | Alur & Cakupan Utama | Alat & Framework | Target Kelulusan |
| --- | --- | --- | --- |
| **Unit Testing (Core)** | Pengujian logika `lq_core` (Penilaian kata, Levenshtein, FSRS, XP). | `cargo test` | Code coverage 100% pada `lq_core`. |
| **Widget Testing** | Pengujian komponen UI Flutter, alur state Riverpod, & bentuk responsif. | `flutter_test`, `alchemist` | 85% cakupan widget kritis. |
| **Integration Testing** | Pengujian end-to-end (E2E) alur pendaftaran, pelajaran, hingga layar hasil. | `patrol`, `integration_test` | Zero critical path failures. |
| **API Contract Test** | Validasi skema respons HTTP Axum terhadap kontrak OpenAPI 3.1. | `wiremock`, `schemathesis` | 100% skema valid. |
| **Load & Stress Test** | Pengujian ketahanan backend menampung 10.000 koneksi pengguna bersamaan. | `k6`, `locust` | Latency p99 < 300 ms, 0% error rate. |

---

## 14. Garis Waktu Pengembangan dan Milestone

```
[Bulan 1-2] Modul Core & Fondasi Architecture (Rust lq_core, Axum API, Drift DB)
[Bulan 3-4] Pengembangan Fitur Utama (UI Pelajaran, Engine Latihan, FSRS SRS)
[Bulan 5]   Pengembangan Fitur Sosial, Liga, Toko, & Integrasi Pembayaran IAP
[Bulan 6]   Integrasi Offline Sync, Pengujian E2E, Hardening Security, & Soft Launch
```