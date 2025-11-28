use crate::models::observation::{Observation, ObservationWithUser};
use chrono::{DateTime, Utc};
use sqlx::{PgPool, Result};
use uuid::Uuid;

/// Repository for observation database operations
pub struct ObservationRepository {
    pool: PgPool,
}

impl ObservationRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Get reference to the pool
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Create a new observation
    pub async fn create(
        &self,
        user_id: Uuid,
        species_name: &str,
        observation_date: DateTime<Utc>,
        location: &str,
        latitude: Option<f64>,
        longitude: Option<f64>,
        notes: Option<&str>,
        photo_url: Option<&str>,
        trip_id: Option<Uuid>,
        is_shared: bool,
    ) -> Result<Observation> {
        let observation = sqlx::query_as::<_, Observation>(
            r#"
            INSERT INTO observations (user_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, trip_id, is_shared)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at
            "#,
        )
        .bind(user_id)
        .bind(species_name)
        .bind(observation_date)
        .bind(location)
        .bind(latitude)
        .bind(longitude)
        .bind(notes)
        .bind(photo_url)
        .bind(trip_id)
        .bind(is_shared)
        .fetch_one(&self.pool)
        .await?;

        Ok(observation)
    }

    /// Find an observation by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<Observation>> {
        let observation = sqlx::query_as::<_, Observation>(
            r#"
            SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at
            FROM observations
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(observation)
    }

    /// Find all observations for a user
    pub async fn find_by_user(&self, user_id: Uuid) -> Result<Vec<Observation>> {
        let observations = sqlx::query_as::<_, Observation>(
            r#"
            SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at
            FROM observations
            WHERE user_id = $1
            ORDER BY observation_date DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(observations)
    }

    /// Find all shared observations with username
    pub async fn find_shared(&self) -> Result<Vec<ObservationWithUser>> {
        let observations = sqlx::query_as::<_, ObservationWithUser>(
            r#"
            SELECT 
                o.id, o.user_id, u.username, o.trip_id, o.species_name, 
                o.observation_date, o.location, o.latitude, o.longitude, o.notes, o.photo_url, 
                o.is_shared, o.created_at, o.updated_at
            FROM observations o
            JOIN users u ON o.user_id = u.id
            WHERE o.is_shared = true
            ORDER BY o.observation_date DESC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(observations)
    }

    /// Update an observation
    pub async fn update(
        &self,
        id: Uuid,
        species_name: Option<&str>,
        observation_date: Option<DateTime<Utc>>,
        location: Option<&str>,
        latitude: Option<Option<f64>>,
        longitude: Option<Option<f64>>,
        notes: Option<&str>,
        photo_url: Option<&str>,
        trip_id: Option<Uuid>,
        is_shared: Option<bool>,
    ) -> Result<Observation> {
        // Build dynamic update query
        let mut query = String::from("UPDATE observations SET updated_at = NOW()");
        let mut param_count = 1;

        if species_name.is_some() {
            param_count += 1;
            query.push_str(&format!(", species_name = ${}", param_count));
        }
        if observation_date.is_some() {
            param_count += 1;
            query.push_str(&format!(", observation_date = ${}", param_count));
        }
        if location.is_some() {
            param_count += 1;
            query.push_str(&format!(", location = ${}", param_count));
        }
        if latitude.is_some() {
            param_count += 1;
            query.push_str(&format!(", latitude = ${}", param_count));
        }
        if longitude.is_some() {
            param_count += 1;
            query.push_str(&format!(", longitude = ${}", param_count));
        }
        if notes.is_some() {
            param_count += 1;
            query.push_str(&format!(", notes = ${}", param_count));
        }
        if photo_url.is_some() {
            param_count += 1;
            query.push_str(&format!(", photo_url = ${}", param_count));
        }
        if trip_id.is_some() {
            param_count += 1;
            query.push_str(&format!(", trip_id = ${}", param_count));
        }
        if is_shared.is_some() {
            param_count += 1;
            query.push_str(&format!(", is_shared = ${}", param_count));
        }

        query.push_str(" WHERE id = $1 RETURNING id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at");

        let mut query_builder = sqlx::query_as::<_, Observation>(&query).bind(id);

        if let Some(val) = species_name {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = observation_date {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = location {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = latitude {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = longitude {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = notes {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = photo_url {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = trip_id {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = is_shared {
            query_builder = query_builder.bind(val);
        }

        let observation = query_builder.fetch_one(&self.pool).await?;

        Ok(observation)
    }

    /// Delete an observation
    pub async fn delete(&self, id: Uuid) -> Result<bool> {
        let result = sqlx::query("DELETE FROM observations WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Search observations by filters
    pub async fn search(
        &self,
        user_id: Uuid,
        species_name: Option<&str>,
        location: Option<&str>,
        start_date: Option<DateTime<Utc>>,
        end_date: Option<DateTime<Utc>>,
    ) -> Result<Vec<Observation>> {
        let mut query = String::from(
            "SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at FROM observations WHERE user_id = $1"
        );
        let mut param_count = 1;

        if species_name.is_some() {
            param_count += 1;
            query.push_str(&format!(" AND LOWER(species_name) LIKE LOWER(${})", param_count));
        }
        if location.is_some() {
            param_count += 1;
            query.push_str(&format!(" AND LOWER(location) LIKE LOWER(${})", param_count));
        }
        if start_date.is_some() {
            param_count += 1;
            query.push_str(&format!(" AND observation_date >= ${}", param_count));
        }
        if end_date.is_some() {
            param_count += 1;
            query.push_str(&format!(" AND observation_date <= ${}", param_count));
        }

        query.push_str(" ORDER BY observation_date DESC");

        let mut query_builder = sqlx::query_as::<_, Observation>(&query).bind(user_id);

        if let Some(val) = species_name {
            query_builder = query_builder.bind(format!("%{}%", val));
        }
        if let Some(val) = location {
            query_builder = query_builder.bind(format!("%{}%", val));
        }
        if let Some(val) = start_date {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = end_date {
            query_builder = query_builder.bind(val);
        }

        let observations = query_builder.fetch_all(&self.pool).await?;

        Ok(observations)
    }

    /// Find observations within a radius of a center point
    pub async fn find_nearby(
        &self,
        center_lat: f64,
        center_lng: f64,
        radius_km: f64,
        user_id: Option<Uuid>,
        species_name: Option<&str>,
    ) -> Result<Vec<Observation>> {
        use crate::services::geo_service::GeoService;

        // Build query based on filters
        let query = match (user_id, species_name) {
            (Some(_), Some(_)) => {
                "SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at 
                 FROM observations 
                 WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND user_id = $1 AND LOWER(species_name) LIKE LOWER($2)"
            }
            (Some(_), None) => {
                "SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at 
                 FROM observations 
                 WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND user_id = $1"
            }
            (None, Some(_)) => {
                "SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at 
                 FROM observations 
                 WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND LOWER(species_name) LIKE LOWER($1)"
            }
            (None, None) => {
                "SELECT id, user_id, trip_id, species_name, observation_date, location, latitude, longitude, notes, photo_url, is_shared, created_at, updated_at 
                 FROM observations 
                 WHERE latitude IS NOT NULL AND longitude IS NOT NULL"
            }
        };

        let mut query_builder = sqlx::query_as::<_, Observation>(query);

        // Bind parameters based on what's provided
        query_builder = match (user_id, species_name) {
            (Some(uid), Some(species)) => {
                query_builder.bind(uid).bind(format!("%{}%", species))
            }
            (Some(uid), None) => {
                query_builder.bind(uid)
            }
            (None, Some(species)) => {
                query_builder.bind(format!("%{}%", species))
            }
            (None, None) => query_builder,
        };

        let all_observations = query_builder.fetch_all(&self.pool).await?;

        // Filter by distance using Haversine formula
        let nearby_observations: Vec<Observation> = all_observations
            .into_iter()
            .filter(|obs| {
                if let (Some(lat), Some(lng)) = (obs.latitude, obs.longitude) {
                    let distance = GeoService::haversine_distance(center_lat, center_lng, lat, lng);
                    distance <= radius_km
                } else {
                    false
                }
            })
            .collect();

        Ok(nearby_observations)
    }
}
