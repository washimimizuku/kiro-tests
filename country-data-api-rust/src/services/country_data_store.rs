use crate::models::Country;
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct CountryDataStore {
    countries: Arc<RwLock<Vec<Country>>>,
}

impl CountryDataStore {
    pub fn new() -> Self {
        Self {
            countries: Arc::new(RwLock::new(Vec::new())),
        }
    }

    pub async fn load_countries(&self, countries: Vec<Country>) {
        let valid_countries: Vec<Country> = countries
            .into_iter()
            .filter(|c| {
                if !c.validate() {
                    tracing::error!("Invalid country data rejected: {}", c.name);
                    false
                } else {
                    true
                }
            })
            .collect();

        let mut store = self.countries.write().await;
        *store = valid_countries;
    }

    pub async fn get_all(&self) -> Vec<Country> {
        self.countries.read().await.clone()
    }

    pub async fn get_by_name(&self, name: &str) -> Option<Country> {
        let name_lower = name.to_lowercase();
        self.countries
            .read()
            .await
            .iter()
            .find(|c| c.name.to_lowercase() == name_lower)
            .cloned()
    }

    pub async fn filter_by_region(&self, region: &str) -> Vec<Country> {
        let region_lower = region.to_lowercase();
        self.countries
            .read()
            .await
            .iter()
            .filter(|c| c.region.to_lowercase() == region_lower)
            .cloned()
            .collect()
    }

    pub async fn search_by_name(&self, query: &str) -> Vec<Country> {
        if query.trim().is_empty() {
            return self.get_all().await;
        }

        let query_lower = query.to_lowercase();
        self.countries
            .read()
            .await
            .iter()
            .filter(|c| c.name.to_lowercase().contains(&query_lower))
            .cloned()
            .collect()
    }
}
