mod api;
mod models;
mod sample_data;
mod services;

use services::CountryDataStore;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let store = CountryDataStore::new();
    store.load_countries(sample_data::get_sample_countries()).await;

    let app = api::create_routes(store);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:5000")
        .await
        .unwrap();
    
    tracing::info!("Country Data API running on http://127.0.0.1:5000");

    axum::serve(listener, app).await.unwrap();
}
