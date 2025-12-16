use crate::utils::jwt::{validate_token, Claims};
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpMessage,
};
use std::pin::Pin;
use std::task::{Context, Poll};
use std::future::{ready, Ready};

/// Middleware for JWT authentication
pub struct AuthMiddleware;

impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = AuthMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthMiddlewareService { service }))
    }
}

pub struct AuthMiddlewareService<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for AuthMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Pin<Box<dyn std::future::Future<Output = Result<Self::Response, Self::Error>>>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let auth_header = req.headers().get("Authorization");

        let token = match auth_header {
            Some(header_value) => {
                let auth_str = match header_value.to_str() {
                    Ok(s) => s,
                    Err(_) => {
                        return Box::pin(async {
                            Err(actix_web::error::ErrorUnauthorized("Invalid authorization header"))
                        });
                    }
                };

                if auth_str.starts_with("Bearer ") {
                    &auth_str[7..]
                } else {
                    return Box::pin(async {
                        Err(actix_web::error::ErrorUnauthorized("Invalid authorization format"))
                    });
                }
            }
            None => {
                return Box::pin(async {
                    Err(actix_web::error::ErrorUnauthorized("Missing authorization header"))
                });
            }
        };

        let claims = match validate_token(token) {
            Ok(claims) => claims,
            Err(_) => {
                return Box::pin(async {
                    Err(actix_web::error::ErrorUnauthorized("Invalid or expired token"))
                });
            }
        };

        // Insert claims into request extensions for later use
        req.extensions_mut().insert(claims);

        let fut = self.service.call(req);
        Box::pin(async move {
            let res = fut.await?;
            Ok(res)
        })
    }
}

/// Extract claims from request extensions
pub fn extract_claims(req: &actix_web::HttpRequest) -> Result<Claims, actix_web::Error> {
    req.extensions()
        .get::<Claims>()
        .cloned()
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("No authentication claims found"))
}

