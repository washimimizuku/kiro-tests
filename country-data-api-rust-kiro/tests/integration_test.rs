use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use country_data_api_rust_kiro::{
    api::create_routes, sample_data, services::CountryDataStore,
};
use tower::util::ServiceExt;

#[tokio::test]
async fn test_full_application_startup_with_sample_data() {
    let store = CountryDataStore::new();
    store.load_countries(sample_data::get_sample_countries()).await;

    let countries = store.get_all().await;
    assert!(countries.len() >= 15, "Should have at least 15 countries");
}

#[tokio::test]
async fn test_all_endpoints_work_together() {
    let store = CountryDataStore::new();
    store.load_countries(sample_data::get_sample_countries()).await;
    let app = create_routes(store);

    // Test get all countries
    let response = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/countries")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    // Test get specific country
    let response = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/countries/France")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    // Test region filter
    let response = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/countries?region=Europe")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    // Test search
    let response = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/countries?search=United")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_error_handling_in_complete_request_flow() {
    let store = CountryDataStore::new();
    store.load_countries(sample_data::get_sample_countries()).await;
    let app = create_routes(store);

    // Test 404 for non-existent country
    let response = app
        .clone()
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
    let error: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert!(error.get("error").is_some());
}
