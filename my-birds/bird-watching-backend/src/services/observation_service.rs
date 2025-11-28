use crate::models::observation::{
    CreateObservationRequest, Observation, ObservationWithUser, UpdateObservationRequest,
};
use crate::repositories::observation_repository::ObservationRepository;
use crate::services::coordinate_validator::CoordinateValidator;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct ObservationService {
    observation_repo: ObservationRepository,
}

impl ObservationService {
    pub fn new(pool: PgPool) -> Self {
        Self {
            observation_repo: ObservationRepository::new(pool),
        }
    }

    /// Create a new observation
    pub async fn create(
        &self,
        user_id: Uuid,
        req: CreateObservationRequest,
    ) -> Result<Observation, String> {
        // Validate observation date is not in the future
        if req.observation_date > Utc::now() {
            return Err("Observation date cannot be in the future".to_string());
        }

        // Validate coordinates if provided
        CoordinateValidator::validate_coordinate_pair(req.latitude, req.longitude)
            .map_err(|e| e.to_string())?;

        let observation = self
            .observation_repo
            .create(
                user_id,
                &req.species_name,
                req.observation_date,
                &req.location,
                req.latitude,
                req.longitude,
                req.notes.as_deref(),
                req.photo_url.as_deref(),
                req.trip_id,
                req.is_shared,
            )
            .await
            .map_err(|e| e.to_string())?;

        Ok(observation)
    }

    /// Get an observation by ID
    pub async fn get_by_id(&self, id: Uuid) -> Result<Observation, String> {
        self.observation_repo
            .find_by_id(id)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "Observation not found".to_string())
    }

    /// Get all observations for a user
    pub async fn get_user_observations(&self, user_id: Uuid) -> Result<Vec<Observation>, String> {
        self.observation_repo
            .find_by_user(user_id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Get all shared observations
    pub async fn get_shared_observations(&self) -> Result<Vec<ObservationWithUser>, String> {
        self.observation_repo
            .find_shared()
            .await
            .map_err(|e| e.to_string())
    }

    /// Update an observation
    pub async fn update(
        &self,
        id: Uuid,
        user_id: Uuid,
        req: UpdateObservationRequest,
    ) -> Result<Observation, String> {
        // Check if observation exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.user_id != user_id {
            return Err("Unauthorized: You can only update your own observations".to_string());
        }

        // Validate observation date is not in the future if provided
        if let Some(date) = req.observation_date {
            if date > Utc::now() {
                return Err("Observation date cannot be in the future".to_string());
            }
        }

        // Validate coordinates if provided
        CoordinateValidator::validate_coordinate_pair(req.latitude, req.longitude)
            .map_err(|e| e.to_string())?;

        let observation = self
            .observation_repo
            .update(
                id,
                req.species_name.as_deref(),
                req.observation_date,
                req.location.as_deref(),
                Some(req.latitude),
                Some(req.longitude),
                req.notes.as_deref(),
                req.photo_url.as_deref(),
                req.trip_id,
                req.is_shared,
            )
            .await
            .map_err(|e| e.to_string())?;

        Ok(observation)
    }

    /// Delete an observation
    pub async fn delete(&self, id: Uuid, user_id: Uuid) -> Result<(), String> {
        // Check if observation exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.user_id != user_id {
            return Err("Unauthorized: You can only delete your own observations".to_string());
        }

        // Delete associated photo if exists
        if let Some(photo_url) = &existing.photo_url {
            let photo_service = crate::services::photo_service::PhotoService::new("./uploads");
            let _ = photo_service.delete_photo(photo_url); // Don't fail if photo deletion fails
        }

        self.observation_repo
            .delete(id)
            .await
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Search observations
    pub async fn search(
        &self,
        user_id: Uuid,
        species_name: Option<String>,
        location: Option<String>,
        start_date: Option<DateTime<Utc>>,
        end_date: Option<DateTime<Utc>>,
    ) -> Result<Vec<Observation>, String> {
        self.observation_repo
            .search(
                user_id,
                species_name.as_deref(),
                location.as_deref(),
                start_date,
                end_date,
            )
            .await
            .map_err(|e| e.to_string())
    }

    /// Find observations near a location
    pub async fn find_nearby(
        &self,
        center_lat: f64,
        center_lng: f64,
        radius_km: f64,
        user_id: Option<Uuid>,
        species_name: Option<String>,
    ) -> Result<Vec<crate::models::observation::ObservationWithDistance>, String> {
        use crate::services::geo_service::GeoService;

        // Validate center coordinates
        CoordinateValidator::validate_latitude(center_lat).map_err(|e| e.to_string())?;
        CoordinateValidator::validate_longitude(center_lng).map_err(|e| e.to_string())?;

        // Validate radius
        if radius_km <= 0.0 || !radius_km.is_finite() {
            return Err("Radius must be a positive number".to_string());
        }

        let observations = self
            .observation_repo
            .find_nearby(center_lat, center_lng, radius_km, user_id, species_name.as_deref())
            .await
            .map_err(|e| e.to_string())?;

        // Calculate distances and create ObservationWithDistance objects
        let observations_with_distance: Vec<crate::models::observation::ObservationWithDistance> =
            observations
                .into_iter()
                .filter_map(|obs| {
                    if let (Some(lat), Some(lng)) = (obs.latitude, obs.longitude) {
                        let distance = GeoService::haversine_distance(center_lat, center_lng, lat, lng);
                        Some(crate::models::observation::ObservationWithDistance {
                            observation: obs,
                            distance_km: distance,
                        })
                    } else {
                        None
                    }
                })
                .collect();

        Ok(observations_with_distance)
    }
}
