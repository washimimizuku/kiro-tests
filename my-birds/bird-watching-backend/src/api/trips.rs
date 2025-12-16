use crate::middleware::auth::extract_claims;
use crate::models::trip::{CreateTripRequest, UpdateTripRequest};
use crate::services::trip_service::TripService;
use crate::utils::jwt::extract_user_id;
use actix_web::{web, HttpRequest, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;

/// POST /api/trips - Create a new trip
pub async fn create_trip(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<CreateTripRequest>,
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

    let trip_service = TripService::new(pool.get_ref().clone());

    match trip_service.create(user_id, body.into_inner()).await {
        Ok(trip) => HttpResponse::Created().json(trip),
        Err(e) => HttpResponse::BadRequest().json(serde_json::json!({
            "error": e
        })),
    }
}

/// GET /api/trips - Get user's trips
pub async fn get_trips(pool: web::Data<PgPool>, req: HttpRequest) -> impl Responder {
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

    let trip_service = TripService::new(pool.get_ref().clone());

    match trip_service.get_user_trips(user_id).await {
        Ok(trips) => HttpResponse::Ok().json(trips),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": e
        })),
    }
}

/// GET /api/trips/:id - Get a specific trip with observations
pub async fn get_trip(
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

    let trip_id = path.into_inner();
    let trip_service = TripService::new(pool.get_ref().clone());

    match trip_service.get_trip_with_observations(trip_id).await {
        Ok((trip, observations)) => HttpResponse::Ok().json(serde_json::json!({
            "trip": trip,
            "observations": observations
        })),
        Err(e) => HttpResponse::NotFound().json(serde_json::json!({
            "error": e
        })),
    }
}

/// PUT /api/trips/:id - Update a trip
pub async fn update_trip(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    path: web::Path<Uuid>,
    body: web::Json<UpdateTripRequest>,
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

    let trip_id = path.into_inner();
    let trip_service = TripService::new(pool.get_ref().clone());

    match trip_service
        .update(trip_id, user_id, body.into_inner())
        .await
    {
        Ok(trip) => HttpResponse::Ok().json(trip),
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

/// DELETE /api/trips/:id - Delete a trip
pub async fn delete_trip(
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

    let trip_id = path.into_inner();
    let trip_service = TripService::new(pool.get_ref().clone());

    match trip_service.delete(trip_id, user_id).await {
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

/// Configure trip routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/trips")
            .route("", web::post().to(create_trip))
            .route("", web::get().to(get_trips))
            .route("/{id}", web::get().to(get_trip))
            .route("/{id}", web::put().to(update_trip))
            .route("/{id}", web::delete().to(delete_trip)),
    );
}
