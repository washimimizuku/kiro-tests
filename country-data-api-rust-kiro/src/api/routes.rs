use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};

use crate::services::CountryDataStore;

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

#[derive(Deserialize)]
pub struct CountryQuery {
    region: Option<String>,
    search: Option<String>,
}

pub fn create_routes(store: CountryDataStore) -> Router {
    Router::new()
        .route("/api/countries", get(get_countries))
        .route("/api/countries/:name", get(get_country_by_name))
        .with_state(store)
}

async fn get_countries(
    State(store): State<CountryDataStore>,
    Query(params): Query<CountryQuery>,
) -> impl IntoResponse {
    let countries = if let Some(region) = params.region {
        store.filter_by_region(&region).await
    } else if let Some(search) = params.search {
        store.search_by_name(&search).await
    } else {
        store.get_all().await
    };

    Json(countries)
}

async fn get_country_by_name(
    State(store): State<CountryDataStore>,
    Path(name): Path<String>,
) -> impl IntoResponse {
    match store.get_by_name(&name).await {
        Some(country) => (StatusCode::OK, Json(country)).into_response(),
        None => (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: format!("Country \"{}\" not found", name),
            }),
        )
            .into_response(),
    }
}
