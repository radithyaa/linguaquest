//! C-ABI JSON untuk Dart FFI.
//!
//! Setiap fungsi publik di `api` diekspos melalui satu pintu `lq_generate_symbol`
//! yang menerima JSON `{ "fn": "nama", ...args }` dan mengembalikan JSON.
//! Fungsi tingkat atas (`lq_evaluate_answer`, dst.) juga diekspor agar dapat
//! dipanggil langsung (mis. dari test atau platform lain).
//!
//! Kontrak memori:
//! - String permintaan dialokasikan klien via `lq_alloc(n)`.
//! - String hasil dialokasikan Rust dan WAJIB dibebaskan via `lq_string_free`.

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_void};

use lq_core::EvaluationResult;
use lq_types::{AnswerEvaluation, EvaluationStatus, SrsCard};

use crate::api;

fn to_c_string(value: String) -> *mut c_char {
    match CString::new(value) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

fn read_c_string(pointer: *const c_char) -> String {
    if pointer.is_null() {
        return String::new();
    }
    unsafe { CStr::from_ptr(pointer) }.to_string_lossy().into_owned()
}

fn evaluate_response(input: &str, correct: &str, alternatives: &[String]) -> AnswerEvaluation {
    match lq_core::check_answer(input, correct, alternatives) {
        EvaluationResult::Correct => AnswerEvaluation {
            status: EvaluationStatus::Correct,
            canonical_answer: correct.to_string(),
            distance: 0,
        },
        EvaluationResult::TypoWarning(canonical) => {
            let distance = lq_core::levenshtein_distance(
                &lq_core::normalize_text(input),
                &lq_core::normalize_text(&canonical),
            ) as i32;
            AnswerEvaluation {
                status: EvaluationStatus::TypoWarning,
                canonical_answer: canonical,
                distance,
            }
        }
        EvaluationResult::Incorrect => AnswerEvaluation {
            status: EvaluationStatus::Incorrect,
            canonical_answer: correct.to_string(),
            distance: -1,
        },
    }
}

fn dispatch(request: serde_json::Value) -> serde_json::Value {
    let function = request["fn"].as_str().unwrap_or_default();
    match function {
        "evaluateAnswer" => {
            let input = request["input"].as_str().unwrap_or_default();
            let correct = request["correctAnswer"].as_str().unwrap_or_default();
            let alternatives: Vec<String> = request["acceptableAnswers"]
                .as_array()
                .map(|items| items.iter().filter_map(|i| i.as_str().map(str::to_string)).collect())
                .unwrap_or_default();
            serde_json::to_value(evaluate_response(input, correct, &alternatives))
                .unwrap_or(serde_json::json!({}))
        }
        "normalize" => {
            serde_json::json!({ "value": lq_core::normalize_text(request["input"].as_str().unwrap_or_default()) })
        }
        "computeXp" => {
            let accuracy = request["accuracy"].as_f64().unwrap_or(0.0) as f32;
            let combo = request["maxCombo"].as_i64().unwrap_or(0) as i32;
            serde_json::json!({ "value": api::compute_xp(accuracy as f64, combo) })
        }
        "recommendedIntervalDays" => {
            let stability = request["stability"].as_f64().unwrap_or(0.0);
            serde_json::json!({ "value": api::recommended_interval_days(stability) })
        }
        "currentRetrievability" => {
            let elapsed = request["elapsedDays"].as_f64().unwrap_or(0.0);
            let stability = request["stability"].as_f64().unwrap_or(0.0);
            serde_json::json!({ "value": api::current_retrievability(elapsed, stability) })
        }
        "applyFsrsRating" => {
            let card: SrsCard = match serde_json::from_value(request["card"].clone()) {
                Ok(card) => card,
                Err(error) => return serde_json::json!({ "error": error.to_string() }),
            };
            let rating = request["rating"].as_i64().unwrap_or(3) as i32;
            match api::apply_fsrs_rating(card, rating) {
                Ok(updated) => serde_json::to_value(updated).unwrap_or(serde_json::json!({})),
                Err(error) => serde_json::json!({ "error": error }),
            }
        }
        _ => serde_json::json!({ "error": format!("fungsi tidak dikenal: {function}") }),
    }
}

/// Alokasi buffer untuk string permintaan (dibebaskan Dart via `lq_string_free`).
#[no_mangle]
pub extern "C" fn lq_alloc(size: usize) -> *mut c_void {
    let mut buffer = Vec::<u8>::with_capacity(size);
    let pointer = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    pointer.cast()
}

/// Bebaskan string hasil (atau buffer) yang dialokasikan Rust.
#[no_mangle]
pub extern "C" fn lq_string_free(pointer: *mut c_char) {
    if pointer.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(pointer));
    }
}

/// Pintu masuk tunggal untuk semua fungsi engine.
#[no_mangle]
pub extern "C" fn lq_generate_symbol(request: *const c_char) -> *mut c_char {
    let raw = read_c_string(request);
    let response = match serde_json::from_str::<serde_json::Value>(&raw) {
        Ok(value) => dispatch(value),
        Err(error) => serde_json::json!({ "error": format!("json tidak valid: {error}") }),
    };
    to_c_string(response.to_string())
}

/// Versi librari (dipakai smoke test FFI).
#[no_mangle]
pub extern "C" fn lq_version() -> *mut c_char {
    to_c_string(env!("CARGO_PKG_VERSION").to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn call(payload: &str) -> serde_json::Value {
        dispatch(serde_json::from_str(payload).unwrap())
    }

    #[test]
    fn evaluate_typo_via_abi() {
        let result = call(r#"{"fn":"evaluateAnswer","input":"tehcer","correctAnswer":"teacher"}"#);
        assert_eq!(result["status"], "typo_warning");
        assert_eq!(result["distance"], 2);
    }

    #[test]
    fn unknown_function_returns_error() {
        let result = call(r#"{"fn":"tidak_ada"}"#);
        assert!(result["error"].as_str().unwrap().contains("tidak dikenal"));
    }

    #[test]
    fn compute_xp_via_abi() {
        let result = call(r#"{"fn":"computeXp","accuracy":1.0,"maxCombo":15}"#);
        assert_eq!(result["value"], 21);
    }
}
