use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use country_data_api_rust_kiro::{api::create_routes, models::Country, services::CountryDataStore};
use serde_json::Value;
use tower::util::ServiceExt;

async fn setup_test_store() -> CountryDataStore {
    let store = CountryDataStore::new();
    store
        .load_countries(vec![
            Country {
                name: "France".to_string(),
                capital: "Paris".to_string(),
                population: 67000000,
                region: "Europe".to_string(),
                languages: vec!["French".to_string()],
            },
            Country {
                name: "Japan".to_string(),
                capital: "Tokyo".to_string(),
                population: 125000000,
                region: "Asia".to_string(),
                languages: vec!["Japanese".to_string()],
            },
            Country {
                name: "United States".to_string(),
                capital: "Washington, D.C.".to_string(),
                population: 331000000,
                region: "Americas".to_string(),
                languages: vec!["English".to_string()],
            },
        ])
        .await;
    store
}

#[tokio::test]
async fn test_get_all_countries_returns_200() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let countries: Vec<Country> = serde_json::from_slice(&body).unwrap();
    assert_eq!(countries.len(), 3);
}

#[tokio::test]
async fn test_get_country_by_name_returns_200() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries/France")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let country: Country = serde_json::from_slice(&body).unwrap();
    assert_eq!(country.name, "France");
}

#[tokio::test]
async fn test_get_country_by_name_returns_404() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries/Atlantis")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::NOT_FOUND);

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let error: Value = serde_json::from_slice(&body).unwrap();
    assert!(error.get("error").is_some());
}

#[tokio::test]
async fn test_region_filter_returns_correct_subset() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries?region=Europe")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let countries: Vec<Country> = serde_json::from_slice(&body).unwrap();
    assert_eq!(countries.len(), 1);
    assert_eq!(countries[0].name, "France");
}

#[tokio::test]
async fn test_name_search_returns_correct_subset() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries?search=United")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let countries: Vec<Country> = serde_json::from_slice(&body).unwrap();
    assert_eq!(countries.len(), 1);
    assert_eq!(countries[0].name, "United States");
}

#[tokio::test]
async fn test_invalid_endpoint_returns_404() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/invalid")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn test_error_response_contains_error_field() {
    let store = setup_test_store().await;
    let app = create_routes(store);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/countries/NonExistent")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();
    let error: Value = serde_json::from_slice(&body).unwrap();
    
    assert!(error.get("error").is_some());
    assert!(error.get("error").unwrap().is_string());
}
