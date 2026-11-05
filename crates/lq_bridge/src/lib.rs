//! Jembatan (bridge) antara Flutter dan mesin bisnis Rust `lq_core`.
//!
//! - **Native (Android/iOS/Desktop):** semua fungsi `#[flutter_rust_bridge::frb(sync)]`
//!   dipanggil langsung lewat C-FFI (satu proses biner, tanpa serialisasi network).
//! - **Web:** modul yang sama dikompilasi ke `wasm32-unknown-unknown`.
//!
//! Semua fungsi publik di `api` bersifat murni (pure) untuk jawaban & FSRS,
//! sedangkan fungsi penggabung state (XP, streak, heart) memakai state lokal
//! yang dimiliki klien sehingga tetap konsisten saat offline.

pub mod api;
pub mod ffi;

/// Re-export type kontrak bersama agar generator `flutter_rust_bridge`
/// menghasilkan kelas Dart yang sama dengan DTO server.
pub use lq_types::{
    AnswerEvaluation, EvaluationStatus, FsrsRating, SrsCard, UserStats,
};
