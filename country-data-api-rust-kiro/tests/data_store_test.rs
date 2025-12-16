use country_data_api_rust_kiro::models::Country;
use country_data_api_rust_kiro::services::CountryDataStore;
use proptest::prelude::*;

fn country_strategy() -> impl Strategy<Value = Country> {
    (
        "[a-zA-Z][a-zA-Z ]{0,49}",
        "[a-zA-Z][a-zA-Z ]{0,49}",
        0i64..10_000_000_000i64,
        "[a-zA-Z]{1,20}",
        prop::collection::vec("[a-zA-Z]{1,20}", 1..5),
    )
        .prop_map(|(name, capital, population, region, languages)| Country {
            name,
            capital,
            population,
            region,
            languages,
        })
}

// Feature: country-data-api-rust, Property 1: Complete country retrieval
proptest! {
    #[test]
    fn test_complete_country_retrieval(
        countries in prop::collection::vec(country_strategy(), 1..20)
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let store = CountryDataStore::new();
            store.load_countries(countries.clone()).await;
            
            let retrieved = store.get_all().await;
            assert_eq!(retrieved.len(), countries.len());
            
            for country in &countries {
                assert!(retrieved.contains(country));
            }
        });
    }
}

// Feature: country-data-api-rust, Property 4: Country retrieval by name
proptest! {
    #[test]
    fn test_country_retrieval_by_name(
        countries in prop::collection::vec(country_strategy(), 1..10)
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let store = CountryDataStore::new();
            
            // Ensure unique names by deduplicating
            let mut unique_countries = Vec::new();
            let mut seen_names = std::collections::HashSet::new();
            for country in countries {
                let name_lower = country.name.to_lowercase();
                if !seen_names.contains(&name_lower) {
                    seen_names.insert(name_lower);
                    unique_countries.push(country);
                }
            }
            
            if unique_countries.is_empty() {
                return;
            }
            
            store.load_countries(unique_countries.clone()).await;
            
            for country in &unique_countries {
                let retrieved = store.get_by_name(&country.name).await;
                assert_eq!(retrieved, Some(country.clone()));
                
                // Test case-insensitive
                let retrieved_upper = store.get_by_name(&country.name.to_uppercase()).await;
                assert_eq!(retrieved_upper, Some(country.clone()));
            }
        });
    }
}

// Feature: country-data-api-rust, Property 5: Region filtering is case-insensitive and accurate
proptest! {
    #[test]
    fn test_region_filtering(
        countries in prop::collection::vec(country_strategy(), 1..20)
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let store = CountryDataStore::new();
            store.load_countries(countries.clone()).await;
            
            for country in &countries {
                let filtered = store.filter_by_region(&country.region).await;
                
                // All returned countries should match the region
                for c in &filtered {
                    assert_eq!(c.region.to_lowercase(), country.region.to_lowercase());
                }
                
                // The original country should be in the results
                assert!(filtered.iter().any(|c| c == country));
                
                // Test case-insensitive
                let filtered_upper = store.filter_by_region(&country.region.to_uppercase()).await;
                assert_eq!(filtered.len(), filtered_upper.len());
            }
        });
    }
}

// Feature: country-data-api-rust, Property 6: Name search is case-insensitive substring matching
proptest! {
    #[test]
    fn test_name_search(
        countries in prop::collection::vec(country_strategy(), 1..20)
    ) {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let store = CountryDataStore::new();
            store.load_countries(countries.clone()).await;
            
            for country in &countries {
                if country.name.len() >= 3 {
                    let query = &country.name[0..3];
                    let results = store.search_by_name(query).await;
                    
                    // All results should contain the query
                    for c in &results {
                        assert!(c.name.to_lowercase().contains(&query.to_lowercase()));
                    }
                    
                    // The original country should be in results
                    assert!(results.iter().any(|c| c == country));
                    
                    // Test case-insensitive
                    let results_upper = store.search_by_name(&query.to_uppercase()).await;
                    assert_eq!(results.len(), results_upper.len());
                }
            }
        });
    }
}

#[tokio::test]
async fn test_empty_store_returns_empty_array() {
    let store = CountryDataStore::new();
    let countries = store.get_all().await;
    assert!(countries.is_empty());
}

#[tokio::test]
async fn test_nonexistent_country_returns_none() {
    let store = CountryDataStore::new();
    let country = store.get_by_name("Atlantis").await;
    assert!(country.is_none());
}

#[tokio::test]
async fn test_empty_region_filter_returns_empty_array() {
    let store = CountryDataStore::new();
    store.load_countries(vec![
        Country {
            name: "France".to_string(),
            capital: "Paris".to_string(),
            population: 67000000,
            region: "Europe".to_string(),
            languages: vec!["French".to_string()],
        }
    ]).await;
    
    let results = store.filter_by_region("Antarctica").await;
    assert!(results.is_empty());
}

#[tokio::test]
async fn test_empty_search_returns_all_countries() {
    let store = CountryDataStore::new();
    let countries = vec![
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
        }
    ];
    store.load_countries(countries.clone()).await;
    
    let results = store.search_by_name("").await;
    assert_eq!(results.len(), 2);
}

#[tokio::test]
async fn test_whitespace_search_returns_all_countries() {
    let store = CountryDataStore::new();
    let countries = vec![
        Country {
            name: "France".to_string(),
            capital: "Paris".to_string(),
            population: 67000000,
            region: "Europe".to_string(),
            languages: vec!["French".to_string()],
        }
    ];
    store.load_countries(countries.clone()).await;
    
    let results = store.search_by_name("   ").await;
    assert_eq!(results.len(), 1);
}
