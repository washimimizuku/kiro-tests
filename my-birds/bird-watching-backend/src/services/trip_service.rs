use crate::models::observation::Observation;
use crate::models::trip::{CreateTripRequest, Trip, UpdateTripRequest};
use crate::repositories::observation_repository::ObservationRepository;
use crate::repositories::trip_repository::TripRepository;
use sqlx::PgPool;
use uuid::Uuid;

pub struct TripService {
    trip_repo: TripRepository,
    observation_repo: ObservationRepository,
}

impl TripService {
    pub fn new(pool: PgPool) -> Self {
        Self {
            trip_repo: TripRepository::new(pool.clone()),
            observation_repo: ObservationRepository::new(pool),
        }
    }

    /// Create a new trip
    pub async fn create(&self, user_id: Uuid, req: CreateTripRequest) -> Result<Trip, String> {
        let trip = self
            .trip_repo
            .create(
                user_id,
                &req.name,
                req.trip_date,
                &req.location,
                req.description.as_deref(),
            )
            .await
            .map_err(|e| e.to_string())?;

        Ok(trip)
    }

    /// Get a trip by ID
    pub async fn get_by_id(&self, id: Uuid) -> Result<Trip, String> {
        self.trip_repo
            .find_by_id(id)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "Trip not found".to_string())
    }

    /// Get trip with observations
    pub async fn get_trip_with_observations(
        &self,
        id: Uuid,
    ) -> Result<(Trip, Vec<Observation>), String> {
        let trip = self.get_by_id(id).await?;

        // Get observations for this trip
        let observations = sqlx::query_as::<_, Observation>(
            r#"
            SELECT id, user_id, trip_id, species_name, observation_date, location, notes, photo_url, is_shared, created_at, updated_at
            FROM observations
            WHERE trip_id = $1
            ORDER BY observation_date DESC
            "#,
        )
        .bind(id)
        .fetch_all(self.observation_repo.pool())
        .await
        .map_err(|e| e.to_string())?;

        Ok((trip, observations))
    }

    /// Get all trips for a user
    pub async fn get_user_trips(&self, user_id: Uuid) -> Result<Vec<Trip>, String> {
        self.trip_repo
            .find_by_user(user_id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Update a trip
    pub async fn update(
        &self,
        id: Uuid,
        user_id: Uuid,
        req: UpdateTripRequest,
    ) -> Result<Trip, String> {
        // Check if trip exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.user_id != user_id {
            return Err("Unauthorized: You can only update your own trips".to_string());
        }

        let trip = self
            .trip_repo
            .update(
                id,
                req.name.as_deref(),
                req.trip_date,
                req.location.as_deref(),
                req.description.as_deref(),
            )
            .await
            .map_err(|e| e.to_string())?;

        Ok(trip)
    }

    /// Delete a trip
    pub async fn delete(&self, id: Uuid, user_id: Uuid) -> Result<(), String> {
        // Check if trip exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.user_id != user_id {
            return Err("Unauthorized: You can only delete your own trips".to_string());
        }

        self.trip_repo
            .delete(id)
            .await
            .map_err(|e| e.to_string())?;

        Ok(())
    }
}
