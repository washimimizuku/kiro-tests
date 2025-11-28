use crate::models::trip::Trip;
use chrono::{DateTime, Utc};
use sqlx::{PgPool, Result};
use uuid::Uuid;

/// Repository for trip database operations
pub struct TripRepository {
    pool: PgPool,
}

impl TripRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Create a new trip
    pub async fn create(
        &self,
        user_id: Uuid,
        name: &str,
        trip_date: DateTime<Utc>,
        location: &str,
        description: Option<&str>,
    ) -> Result<Trip> {
        let trip = sqlx::query_as::<_, Trip>(
            r#"
            INSERT INTO trips (user_id, name, trip_date, location, description)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, user_id, name, trip_date, location, description, created_at, updated_at
            "#,
        )
        .bind(user_id)
        .bind(name)
        .bind(trip_date)
        .bind(location)
        .bind(description)
        .fetch_one(&self.pool)
        .await?;

        Ok(trip)
    }

    /// Find a trip by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<Trip>> {
        let trip = sqlx::query_as::<_, Trip>(
            r#"
            SELECT id, user_id, name, trip_date, location, description, created_at, updated_at
            FROM trips
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(trip)
    }

    /// Find all trips for a user
    pub async fn find_by_user(&self, user_id: Uuid) -> Result<Vec<Trip>> {
        let trips = sqlx::query_as::<_, Trip>(
            r#"
            SELECT id, user_id, name, trip_date, location, description, created_at, updated_at
            FROM trips
            WHERE user_id = $1
            ORDER BY trip_date DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(trips)
    }

    /// Update a trip
    pub async fn update(
        &self,
        id: Uuid,
        name: Option<&str>,
        trip_date: Option<DateTime<Utc>>,
        location: Option<&str>,
        description: Option<&str>,
    ) -> Result<Trip> {
        // Build dynamic update query
        let mut query = String::from("UPDATE trips SET updated_at = NOW()");
        let mut param_count = 1;

        if name.is_some() {
            param_count += 1;
            query.push_str(&format!(", name = ${}", param_count));
        }
        if trip_date.is_some() {
            param_count += 1;
            query.push_str(&format!(", trip_date = ${}", param_count));
        }
        if location.is_some() {
            param_count += 1;
            query.push_str(&format!(", location = ${}", param_count));
        }
        if description.is_some() {
            param_count += 1;
            query.push_str(&format!(", description = ${}", param_count));
        }

        query.push_str(" WHERE id = $1 RETURNING id, user_id, name, trip_date, location, description, created_at, updated_at");

        let mut query_builder = sqlx::query_as::<_, Trip>(&query).bind(id);

        if let Some(val) = name {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = trip_date {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = location {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = description {
            query_builder = query_builder.bind(val);
        }

        let trip = query_builder.fetch_one(&self.pool).await?;

        Ok(trip)
    }

    /// Delete a trip (observations will have trip_id set to NULL via ON DELETE SET NULL)
    pub async fn delete(&self, id: Uuid) -> Result<bool> {
        let result = sqlx::query("DELETE FROM trips WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }
}
