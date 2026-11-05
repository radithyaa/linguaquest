//! Router utama `/v1/` (SRS Bab 7.2).

use axum::routing::{delete, get, patch, post};
use axum::Router;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

use crate::routes;
use crate::AppState;

pub fn router(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let api = Router::new()
        .route("/health", get(routes::health::health))
        .route("/auth/register", post(routes::auth::register))
        .route("/auth/login", post(routes::auth::login))
        .route("/auth/guest", post(routes::auth::guest))
        .route("/auth/refresh", post(routes::auth::refresh))
        .route("/auth/upgrade", post(routes::auth::upgrade))
        .route("/auth/logout", post(routes::auth::logout))
        .route("/me", get(routes::profile::profile))
        .route("/me", patch(routes::profile::update_profile))
        .route("/me/wallet", get(routes::shop::wallet))
        .route("/courses", get(routes::curriculum::courses))
        .route("/courses/{id}/curriculum", get(routes::curriculum::curriculum))
        .route("/lessons/{node_id}", get(routes::curriculum::lesson))
        .route("/sessions/start", post(routes::sessions::start))
        .route("/sessions/complete", post(routes::sessions::complete))
        .route("/practice", get(routes::practice::overview))
        .route("/practice/review", post(routes::practice::review))
        .route("/quests", get(routes::quests::overview))
        .route("/quests/{code}/claim", post(routes::quests::claim))
        .route("/league", get(routes::league::overview))
        .route("/shop/catalog", get(routes::shop::catalog))
        .route("/shop/buy", post(routes::shop::buy))
        .route("/sync", post(routes::sync::sync))
        .route("/stt/transcribe", post(routes::stt::transcribe))
        .route("/admin/units", post(routes::admin::create_unit))
        .route("/admin/nodes", post(routes::admin::create_node))
        .route("/admin/units/{id}", delete(routes::admin::delete_unit));

    Router::new()
        .nest("/v1", api)
        .layer(TraceLayer::new_for_http())
        .layer(cors)
        .with_state(state)
}
