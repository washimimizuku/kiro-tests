use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// Observation model representing a bird sighting
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Observation {
    pub id: Uuid,
    pub user_id: Uuid,
    pub trip_id: Option<Uuid>,
    pub species_name: String,
    pub observation_date: DateTime<Utc>,
    pub location: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub notes: Option<String>,
    pub photo_url: Option<String>,
    pub is_shared: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Observation response with username (for shared observations)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ObservationWithUser {
    pub id: Uuid,
    pub user_id: Uuid,
    pub username: String,
    pub trip_id: Option<Uuid>,
    pub species_name: String,
    pub observation_date: DateTime<Utc>,
    pub location: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub notes: Option<String>,
    pub photo_url: Option<String>,
    pub is_shared: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Request payload for creating an observation
#[derive(Debug, Deserialize)]
pub struct CreateObservationRequest {
    pub species_name: String,
    pub observation_date: DateTime<Utc>,
    pub location: String,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub notes: Option<String>,
    pub photo_url: Option<String>,
    pub trip_id: Option<Uuid>,
    #[serde(default)]
    pub is_shared: bool,
}

/// Request payload for updating an observation
#[derive(Debug, Deserialize)]
pub struct UpdateObservationRequest {
    pub species_name: Option<String>,
    pub observation_date: Option<DateTime<Utc>>,
    pub location: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub notes: Option<String>,
    pub photo_url: Option<String>,
    pub trip_id: Option<Uuid>,
    pub is_shared: Option<bool>,
}

/// Observation with calculated distance from a reference point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObservationWithDistance {
    #[serde(flatten)]
    pub observation: Observation,
    pub distance_km: f64,
}

/// Observation with user and distance (for shared observations proximity search)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObservationWithUserAndDistance {
    #[serde(flatten)]
    pub observation: ObservationWithUser,
    pub distance_km: f64,
}
