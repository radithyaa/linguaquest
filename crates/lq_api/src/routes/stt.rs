//! Speech-to-Text untuk latihan pelafalan (SRS EXE-07).
//!
//! Klien merekam mikrofon lalu mengirim base64 audio ke endpoint ini.
//! Server meneruskan ke penyedia STT (Whisper/OpenAI atau kustom) sesuai
//! konfigurasi `STT_PROVIDER`. Bila `STT_PROVIDER=none` (default), endpoint
//! membalas `503 STT_NOT_CONFIGURED` agar klien dapat menampilkan mode
//! latihan tanpa penilaian otomatis.

use axum::extract::State;
use axum::Json;
use base64::Engine;
use serde::{Deserialize, Serialize};

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::state::AppState;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscribeRequest {
    /// Audio mentah (m4a/aac/wav) ter-encode base64.
    pub audio_base64: String,
    pub mime_type: String,
    /// Frasa target untuk menghitung skor kemiripan.
    pub expected_text: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscribeResponse {
    pub transcript: String,
    pub matched: bool,
    pub score: f64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SttProvider {
    None,
    Whisper,
}

impl SttProvider {
    pub fn from_env() -> Self {
        match std::env::var("STT_PROVIDER").unwrap_or_else(|_| "none".into()).as_str() {
            "whisper" | "openai" => SttProvider::Whisper,
            _ => SttProvider::None,
        }
    }
}

pub async fn transcribe(
    State(_state): State<AppState>,
    _user: AuthUser,
    Json(payload): Json<TranscribeRequest>,
) -> ApiResult<TranscribeResponse> {
    // Validasi payload audio sebelum memanggil penyedia eksternal.
    let audio = base64::engine::general_purpose::STANDARD
        .decode(payload.audio_base64.as_bytes())
        .map_err(|_| ApiError::bad_request("Audio bukan base64 yang valid."))?;
    if audio.is_empty() {
        return Err(ApiError::bad_request("Audio kosong."));
    }
    if audio.len() > 5 * 1024 * 1024 {
        return Err(ApiError::bad_request("Ukuran audio maksimal 5 MB."));
    }
    if payload.expected_text.trim().is_empty() {
        return Err(ApiError::bad_request("expected_text wajib diisi."));
    }

    let provider = SttProvider::from_env();
    let transcript = match provider {
        SttProvider::None => {
            return Err(ApiError::new(
                axum::http::StatusCode::SERVICE_UNAVAILABLE,
                "STT_NOT_CONFIGURED",
                "Layanan STT Belum Dikonfigurasi",
                "Set STT_PROVIDER=whisper dan OPENAI_API_KEY di server untuk mengaktifkan Speech-to-Text.",
            ))
        }
        SttProvider::Whisper => transcribe_whisper(&audio, &payload.mime_type).await?,
    };

    let score = lq_db::learning::speech_similarity(&payload.expected_text, &transcript);
    Ok(Json(TranscribeResponse {
        transcript,
        matched: score >= lq_db::learning::SPEECH_SIMILARITY_THRESHOLD,
        score,
    }))
}

async fn transcribe_whisper(audio: &[u8], mime_type: &str) -> Result<String, ApiError> {
    let api_key = std::env::var("OPENAI_API_KEY")
        .map_err(|_| ApiError::internal("OPENAI_API_KEY belum diset pada server."))?;
    let model = std::env::var("STT_MODEL").unwrap_or_else(|_| "whisper-1".into());

    let file_name = match mime_type {
        "audio/wav" | "audio/x-wav" => "audio.wav",
        "audio/webm" => "audio.webm",
        _ => "audio.m4a",
    };

    let part = reqwest::multipart::Part::bytes(audio.to_vec())
        .file_name(file_name.to_string())
        .mime_str(mime_type)
        .map_err(|_| ApiError::bad_request("mime_type tidak valid."))?;
    let form = reqwest::multipart::Form::new()
        .part("file", part)
        .text("model", model);

    let response = reqwest::Client::new()
        .post("https://api.openai.com/v1/audio/transcriptions")
        .bearer_auth(api_key)
        .multipart(form)
        .send()
        .await
        .map_err(|error| {
            tracing::error!(%error, "permintaan STT gagal");
            ApiError::new(
                axum::http::StatusCode::BAD_GATEWAY,
                "STT_UPSTREAM_ERROR",
                "Layanan STT Tidak Merespons",
                "Gagal menghubungi penyedia Speech-to-Text.",
            )
        })?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().await.unwrap_or_default();
        tracing::error!(%status, %body, "STT upstream menolak permintaan");
        return Err(ApiError::new(
            axum::http::StatusCode::BAD_GATEWAY,
            "STT_UPSTREAM_ERROR",
            "Layanan STT Menolak Permintaan",
            "Periksa kredensial dan format audio.",
        ));
    }

    #[derive(Deserialize)]
    struct WhisperResponse {
        text: String,
    }
    let parsed: WhisperResponse = response
        .json()
        .await
        .map_err(|_| ApiError::internal("Respons STT tidak dapat dibaca."))?;
    Ok(parsed.text)
}
