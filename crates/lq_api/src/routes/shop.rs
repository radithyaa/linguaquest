//! Toko virtual: katalog, pembelian, dan ledger gems.

use axum::extract::State;
use axum::Json;
use lq_types::{PurchaseRequest, PurchaseResponse, ShopItemDto, WalletEntryDto};

use crate::error::{ApiError, ApiResult, AuthUser};
use crate::AppState;

pub async fn catalog(State(state): State<AppState>, user: AuthUser) -> ApiResult<Vec<ShopItemDto>> {
    let items = state
        .storage
        .read(|s| lq_db::gamification::catalog(s, user.user_id));
    Ok(Json(items))
}

pub async fn buy(
    State(state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<PurchaseRequest>,
) -> ApiResult<PurchaseResponse> {
    let result = state.storage.write(|s| {
        lq_db::gamification::purchase(s, user.user_id, &payload.sku, payload.client_op_id)
    });

    let response = match result {
        Ok(response) => response,
        Err(error) => {
            let status_message = error.detail();
            return Err(match error {
                lq_db::gamification::PurchaseError::InsufficientGems { .. } => {
                    ApiError::forbidden("INSUFFICIENT_GEMS", "Gems Tidak Cukup", status_message)
                }
                lq_db::gamification::PurchaseError::AlreadyOwned => {
                    ApiError::conflict("ALREADY_OWNED", status_message)
                }
                lq_db::gamification::PurchaseError::UnknownSku => ApiError::not_found(status_message),
                lq_db::gamification::PurchaseError::NoUser => ApiError::not_found(status_message),
            });
        }
    };

    state.commit(Some(user.user_id)).await?;
    Ok(Json(response))
}

pub async fn wallet(State(state): State<AppState>, user: AuthUser) -> ApiResult<Vec<WalletEntryDto>> {
    let entries = state
        .storage
        .read(|s| lq_db::gamification::wallet(s, user.user_id));
    Ok(Json(entries))
}
