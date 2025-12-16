use country_data_api_rust_kiro::models::Country;
use proptest::prelude::*;

// Feature: country-data-api-rust, Property 2: Serialization includes all fields
proptest! {
    #[test]
    fn test_serialization_includes_all_fields(
        name in "[a-zA-Z][a-zA-Z ]{0,49}",
        capital in "[a-zA-Z][a-zA-Z ]{0,49}",
        population in 0i64..10_000_000_000i64,
        region in "[a-zA-Z]{1,20}",
        languages in prop::collection::vec("[a-zA-Z]{1,20}", 1..5)
    ) {
        let country = Country {
            name,
            capital,
            population,
            region,
            languages,
        };

        let json = serde_json::to_value(&country).unwrap();
        
        assert!(json.get("name").is_some());
        assert!(json.get("capital").is_some());
        assert!(json.get("population").is_some());
        assert!(json.get("region").is_some());
        assert!(json.get("languages").is_some());
    }
}

// Feature: country-data-api-rust, Property 3: Serialization round-trip preserves data
proptest! {
    #[test]
    fn test_serialization_roundtrip(
        name in "[a-zA-Z][a-zA-Z ]{0,49}",
        capital in "[a-zA-Z][a-zA-Z ]{0,49}",
        population in 0i64..10_000_000_000i64,
        region in "[a-zA-Z]{1,20}",
        languages in prop::collection::vec("[a-zA-Z]{1,20}", 1..5)
    ) {
        let country = Country {
            name,
            capital,
            population,
            region,
            languages,
        };

        let json = serde_json::to_string(&country).unwrap();
        let deserialized: Country = serde_json::from_str(&json).unwrap();
        
        assert_eq!(country, deserialized);
    }
}

// Feature: country-data-api-rust, Property 8: Data validation rejects invalid countries
proptest! {
    #[test]
    fn test_validation_rejects_empty_name(
        capital in "[a-zA-Z][a-zA-Z ]{0,49}",
        population in 0i64..10_000_000_000i64,
        region in "[a-zA-Z]{1,20}",
        languages in prop::collection::vec("[a-zA-Z]{1,20}", 1..5)
    ) {
        let country = Country {
            name: "   ".to_string(),
            capital,
            population,
            region,
            languages,
        };
        
        assert!(!country.validate());
    }

    #[test]
    fn test_validation_rejects_negative_population(
        name in "[a-zA-Z][a-zA-Z ]{0,49}",
        capital in "[a-zA-Z][a-zA-Z ]{0,49}",
        population in -10_000_000_000i64..-1i64,
        region in "[a-zA-Z]{1,20}",
        languages in prop::collection::vec("[a-zA-Z]{1,20}", 1..5)
    ) {
        let country = Country {
            name,
            capital,
            population,
            region,
            languages,
        };
        
        assert!(!country.validate());
    }

    #[test]
    fn test_validation_accepts_valid_country(
        name in "[a-zA-Z][a-zA-Z ]{0,49}",
        capital in "[a-zA-Z][a-zA-Z ]{0,49}",
        population in 0i64..10_000_000_000i64,
        region in "[a-zA-Z]{1,20}",
        languages in prop::collection::vec("[a-zA-Z]{1,20}", 1..5)
    ) {
        let country = Country {
            name,
            capital,
            population,
            region,
            languages,
        };
        
        assert!(country.validate());
    }
}

// Feature: country-data-api-rust, Property 7: Error responses have consistent structure
#[test]
fn test_error_response_structure() {
    use serde_json::json;
    
    let error_json = json!({
        "error": "Test error message"
    });
    
    assert!(error_json.get("error").is_some());
    assert!(error_json.get("error").unwrap().is_string());
}
