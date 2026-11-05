-- LinguaQuest — Ekstensi PostgreSQL yang dibutuhkan (SRS 8.1).
-- UUID v4 dibangkitkan oleh aplikasi (crate `uuid`), ekstensi ini menjaga
-- kompatibilitas fungsi `uuid_generate_v4()` untuk query manual/DBA.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
