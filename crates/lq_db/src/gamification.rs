//! Toko, ledger gems, dan pembelian item.

use chrono::Utc;
use lq_types::{PurchaseResponse, ShopItemDto, WalletEntryDto};
use uuid::Uuid;

use crate::db::{DbState, WalletRow};
use crate::users::to_stats_dto;

pub const SKU_HEART_REFILL: &str = "heart_refill";
pub const SKU_STREAK_FREEZE: &str = "streak_freeze";
pub const SKU_DOUBLE_XP: &str = "double_xp_15m";

pub struct CatalogItem {
    pub sku: &'static str,
    pub title: &'static str,
    pub description: &'static str,
    pub price_gems: i32,
    pub icon: &'static str,
    pub color: &'static str,
}

pub const CATALOG: &[CatalogItem] = &[
    CatalogItem {
        sku: SKU_HEART_REFILL,
        title: "Isi Penuh Hearts",
        description: "Kembalikan seluruh Hearts menjadi 5 secara instan.",
        price_gems: 150,
        icon: "favorite",
        color: "#FF4B4B",
    },
    CatalogItem {
        sku: SKU_STREAK_FREEZE,
        title: "Streak Freeze",
        description: "Lindungi streak kamu jika terlewat belajar satu hari.",
        price_gems: 200,
        icon: "ac_unit",
        color: "#1CB0F6",
    },
    CatalogItem {
        sku: SKU_DOUBLE_XP,
        title: "Double XP Potion (15 Menit)",
        description: "Gandakan XP yang didapatkan di setiap sesi selama 15 menit.",
        price_gems: 100,
        icon: "bolt",
        color: "#FFC800",
    },
];

pub fn catalog(state: &DbState, user_id: Uuid) -> Vec<ShopItemDto> {
    let stats = state.stats.get(&user_id);
    let freezes = stats.map(|s| s.freezes_available).unwrap_or(0);
    CATALOG
        .iter()
        .map(|item| ShopItemDto {
            sku: item.sku.to_string(),
            title: item.title.to_string(),
            description: item.description.to_string(),
            price_gems: item.price_gems,
            icon: item.icon.to_string(),
            color: item.color.to_string(),
            available: stats.is_some(),
            owned: item.sku == SKU_STREAK_FREEZE && freezes > 0,
        })
        .collect()
}

#[derive(Debug)]
pub enum PurchaseError {
    UnknownSku,
    InsufficientGems { needed: i32, available: i32 },
    AlreadyOwned,
    NoUser,
}

impl PurchaseError {
    pub fn code(&self) -> &'static str {
        match self {
            PurchaseError::UnknownSku => "UNKNOWN_SKU",
            PurchaseError::InsufficientGems { .. } => "INSUFFICIENT_GEMS",
            PurchaseError::AlreadyOwned => "ALREADY_OWNED",
            PurchaseError::NoUser => "USER_NOT_FOUND",
        }
    }

    pub fn detail(&self) -> String {
        match self {
            PurchaseError::UnknownSku => "Item toko tidak ditemukan.".into(),
            PurchaseError::InsufficientGems { needed, available } => {
                format!("Gems tidak cukup: butuh {needed}, saldo {available}.")
            }
            PurchaseError::AlreadyOwned => "Streak Freeze hanya dapat dimiliki satu kali.".into(),
            PurchaseError::NoUser => "Pengguna tidak ditemukan.".into(),
        }
    }
}

pub fn purchase(
    state: &mut DbState,
    user_id: Uuid,
    sku: &str,
    client_op_id: Option<Uuid>,
) -> Result<PurchaseResponse, PurchaseError> {
    let item = CATALOG
        .iter()
        .find(|i| i.sku == sku)
        .ok_or(PurchaseError::UnknownSku)?;

    let Some(mut stats) = state.stats.get(&user_id).cloned() else {
        return Err(PurchaseError::NoUser);
    };

    if sku == SKU_STREAK_FREEZE && stats.freezes_available > 0 {
        return Err(PurchaseError::AlreadyOwned);
    }

    let balance = state.wallet_balance(user_id);
    if balance < item.price_gems {
        return Err(PurchaseError::InsufficientGems {
            needed: item.price_gems,
            available: balance,
        });
    }
    if stats.gems < item.price_gems {
        return Err(PurchaseError::InsufficientGems {
            needed: item.price_gems,
            available: stats.gems,
        });
    }

    stats.gems -= item.price_gems;
    match sku {
        SKU_HEART_REFILL => {
            stats.hearts = lq_core::MAX_HEARTS;
            stats.hearts_updated_at = Utc::now();
        }
        SKU_STREAK_FREEZE => stats.freezes_available += 1,
        SKU_DOUBLE_XP => { /* Efek booster diterapkan klien pada sesi berikutnya. */ }
        _ => {}
    }
    state.stats.insert(user_id, stats.clone());

    let ledger_id = state.wallet.iter().map(|w| w.id).max().unwrap_or(0) + 1;
    state.wallet.push(WalletRow {
        id: ledger_id,
        user_id,
        delta: -item.price_gems,
        reason: format!("purchase:{}", sku),
        ref_id: None,
        client_op_id,
        created_at: Utc::now(),
    });

    Ok(PurchaseResponse {
        success: true,
        stats: to_stats_dto(state, &stats, Utc::now()),
        message: format!("{} berhasil dibeli!", item.title),
    })
}

pub fn wallet(state: &DbState, user_id: Uuid) -> Vec<WalletEntryDto> {
    let mut entries: Vec<WalletEntryDto> = state
        .wallet
        .iter()
        .filter(|w| w.user_id == user_id)
        .map(|w| WalletEntryDto {
            id: w.id,
            delta: w.delta,
            reason: w.reason.clone(),
            created_at: w.created_at,
        })
        .collect();
    entries.sort_by(|a, b| b.created_at.cmp(&a.created_at));
    entries
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::StatsRow;

    #[test]
    fn purchase_requires_enough_gems() {
        let mut state = DbState::default();
        let user_id = Uuid::new_v4();
        let mut stats = StatsRow::new(user_id);
        stats.gems = 10;
        state.stats.insert(user_id, stats);
        assert!(matches!(
            purchase(&mut state, user_id, SKU_HEART_REFILL, None),
            Err(PurchaseError::InsufficientGems { .. })
        ));
    }

    #[test]
    fn heart_refill_restores_full_hearts() {
        let mut state = DbState::default();
        let user_id = Uuid::new_v4();
        let mut stats = StatsRow::new(user_id);
        stats.gems = 500;
        stats.hearts = 1;
        state.stats.insert(user_id, stats);
        state.wallet.push(WalletRow {
            id: 1,
            user_id,
            delta: 500,
            reason: "initial".into(),
            ref_id: None,
            client_op_id: None,
            created_at: Utc::now(),
        });
        let response = purchase(&mut state, user_id, SKU_HEART_REFILL, None).unwrap();
        assert_eq!(response.stats.hearts, 5);
        assert_eq!(response.stats.gems, 350);
    }
}
