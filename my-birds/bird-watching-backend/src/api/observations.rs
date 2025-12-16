use crate::middleware::auth::extract_claims;
use crate::models::observation::{CreateObservationRequest, UpdateObservationRequest};
use crate::services::observation_service::ObservationService;
use crate::utils::jwt::extract_user_id;
use actix_web::{web, HttpRequest, HttpResponse, Responder};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

/// POST /api/observations - Create a new observation
pub async fn create_observation(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<CreateObservationRequest>,
) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service.create(user_id, body.into_inner()).await {
        Ok(observation) => HttpResponse::Created().json(observation),
        Err(e) => HttpResponse::BadRequest().json(serde_json::json!({
            "error": e
        })),
    }
}

/// GET /api/observations - Get user's observations
pub async fn get_observations(pool: web::Data<PgPool>, req: HttpRequest) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service.get_user_observations(user_id).await {
        Ok(observations) => HttpResponse::Ok().json(observations),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": e
        })),
    }
}

/// GET /api/observations/:id - Get a specific observation
pub async fn get_observation(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let _claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_id = path.into_inner();
    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service.get_by_id(observation_id).await {
        Ok(observation) => HttpResponse::Ok().json(observation),
        Err(e) => HttpResponse::NotFound().json(serde_json::json!({
            "error": e
        })),
    }
}

/// PUT /api/observations/:id - Update an observation
pub async fn update_observation(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
    body: web::Json<UpdateObservationRequest>,
) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_id = path.into_inner();
    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service
        .update(observation_id, user_id, body.into_inner())
        .await
    {
        Ok(observation) => HttpResponse::Ok().json(observation),
        Err(e) => {
            if e.contains("Unauthorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": e
                }))
            } else {
                HttpResponse::BadRequest().json(serde_json::json!({
                    "error": e
                }))
            }
        }
    }
}

/// DELETE /api/observations/:id - Delete an observation
pub async fn delete_observation(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_id = path.into_inner();
    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service.delete(observation_id, user_id).await {
        Ok(_) => HttpResponse::NoContent().finish(),
        Err(e) => {
            if e.contains("Unauthorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": e
                }))
            } else {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": e
                }))
            }
        }
    }
}

/// GET /api/observations/shared - Get all shared observations
pub async fn get_shared_observations(pool: web::Data<PgPool>, req: HttpRequest) -> impl Responder {
    let _claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service.get_shared_observations().await {
        Ok(observations) => HttpResponse::Ok().json(observations),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": e
        })),
    }
}

#[derive(Deserialize)]
pub struct SearchQuery {
    species: Option<String>,
    location: Option<String>,
    start_date: Option<DateTime<Utc>>,
    end_date: Option<DateTime<Utc>>,
}

/// GET /api/observations/search - Search observations
pub async fn search_observations(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    query: web::Query<SearchQuery>,
) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service
        .search(
            user_id,
            query.species.clone(),
            query.location.clone(),
            query.start_date,
            query.end_date,
        )
        .await
    {
        Ok(observations) => HttpResponse::Ok().json(observations),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": e
        })),
    }
}

#[derive(Deserialize)]
pub struct NearbyQuery {
    lat: f64,
    lng: f64,
    radius: f64,
    user_id: Option<Uuid>,
    species: Option<String>,
}

/// GET /api/observations/nearby - Find observations near a location
pub async fn get_nearby_observations(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    query: web::Query<NearbyQuery>,
) -> impl Responder {
    let _claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let observation_service = ObservationService::new(pool.get_ref().clone());

    match observation_service
        .find_nearby(
            query.lat,
            query.lng,
            query.radius,
            query.user_id,
            query.species.clone(),
        )
        .await
    {
        Ok(observations) => HttpResponse::Ok().json(observations),
        Err(e) => HttpResponse::BadRequest().json(serde_json::json!({
            "error": e
        })),
    }
}

/// Configure observation routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/observations")
            .route("", web::post().to(create_observation))
            .route("", web::get().to(get_observations))
            .route("/shared", web::get().to(get_shared_observations))
            .route("/search", web::get().to(search_observations))
            .route("/nearby", web::get().to(get_nearby_observations))
            .route("/{id}", web::get().to(get_observation))
            .route("/{id}", web::put().to(update_observation))
            .route("/{id}", web::delete().to(delete_observation)),
    );
}
