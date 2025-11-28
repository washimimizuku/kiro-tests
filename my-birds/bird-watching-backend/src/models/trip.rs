use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// Trip model representing a bird watching excursion
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Trip {
    pub id: Uuid,
    pub user_id: Uuid,
    pub name: String,
    pub trip_date: DateTime<Utc>,
    pub location: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Request payload for creating a trip
#[derive(Debug, Deserialize)]
pub struct CreateTripRequest {
    pub name: String,
    pub trip_date: DateTime<Utc>,
    pub location: String,
    pub description: Option<String>,
}

/// Request payload for updating a trip
#[derive(Debug, Deserialize)]
pub struct UpdateTripRequest {
    pub name: Option<String>,
    pub trip_date: Option<DateTime<Utc>>,
    pub location: Option<String>,
    pub description: Option<String>,
}
