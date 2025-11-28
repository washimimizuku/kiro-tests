use crate::middleware::auth::extract_claims;
use crate::models::user::{LoginRequest, RegisterRequest};
use crate::services::auth_service::AuthService;
use actix_web::{web, HttpRequest, HttpResponse, Responder};
use sqlx::PgPool;

/// POST /api/auth/register - Register a new user
pub async fn register(
    pool: web::Data<PgPool>,
    req: web::Json<RegisterRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(pool.get_ref().clone());

    match auth_service.register(req.into_inner()).await {
        Ok(user) => HttpResponse::Created().json(user),
        Err(e) => HttpResponse::BadRequest().json(serde_json::json!({
            "error": e
        })),
    }
}

/// POST /api/auth/login - Authenticate a user
pub async fn login(
    pool: web::Data<PgPool>,
    req: web::Json<LoginRequest>,
) -> impl Responder {
    let auth_service = AuthService::new(pool.get_ref().clone());

    match auth_service.login(req.into_inner()).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => HttpResponse::Unauthorized().json(serde_json::json!({
            "error": e
        })),
    }
}

/// GET /api/users/me - Get current user profile
pub async fn get_me(
    pool: web::Data<PgPool>,
    req: HttpRequest,
) -> impl Responder {
    let claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => return HttpResponse::Unauthorized().json(serde_json::json!({
            "error": e.to_string()
        })),
    };

    let user_id = match uuid::Uuid::parse_str(&claims.sub) {
        Ok(id) => id,
        Err(e) => return HttpResponse::BadRequest().json(serde_json::json!({
            "error": e.to_string()
        })),
    };

    let auth_service = AuthService::new(pool.get_ref().clone());

    match auth_service.get_user_profile(user_id).await {
        Ok(user) => HttpResponse::Ok().json(user),
        Err(e) => HttpResponse::NotFound().json(serde_json::json!({
            "error": e
        })),
    }
}

/// Configure authentication routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/auth")
            .route("/register", web::post().to(register))
            .route("/login", web::post().to(login))
    )
    .service(
        web::scope("/api/users")
            .route("/me", web::get().to(get_me))
    );
}

