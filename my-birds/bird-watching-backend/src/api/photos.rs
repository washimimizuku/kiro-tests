use crate::middleware::auth::extract_claims;
use crate::services::photo_service::PhotoService;
use actix_multipart::Multipart;
use actix_web::{web, HttpRequest, HttpResponse, Responder};

/// POST /api/photos/upload - Upload a photo
pub async fn upload_photo(
    req: HttpRequest,
    payload: Multipart,
) -> impl Responder {
    // Verify authentication
    let _claims = match extract_claims(&req) {
        Ok(claims) => claims,
        Err(e) => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": e.to_string()
            }))
        }
    };

    let photo_service = PhotoService::new("./uploads");

    match photo_service.upload_photo(payload).await {
        Ok(photo_url) => HttpResponse::Ok().json(serde_json::json!({
            "photo_url": photo_url
        })),
        Err(e) => HttpResponse::BadRequest().json(serde_json::json!({
            "error": e
        })),
    }
}

/// Configure photo routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/photos")
            .route("/upload", web::post().to(upload_photo))
    );
}
