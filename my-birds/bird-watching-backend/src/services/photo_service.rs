use actix_multipart::Multipart;
use actix_web::web;
use futures_util::StreamExt;
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use uuid::Uuid;

pub struct PhotoService {
    upload_dir: PathBuf,
}

impl PhotoService {
    pub fn new(upload_dir: &str) -> Self {
        // Create upload directory if it doesn't exist
        fs::create_dir_all(upload_dir).expect("Failed to create upload directory");
        
        Self {
            upload_dir: PathBuf::from(upload_dir),
        }
    }

    /// Upload a photo and return the URL
    pub async fn upload_photo(&self, mut payload: Multipart) -> Result<String, String> {
        while let Some(item) = payload.next().await {
            let mut field = item.map_err(|e| e.to_string())?;
            
            let content_disposition = field.content_disposition();
            let filename = content_disposition
                .get_filename()
                .ok_or_else(|| "No filename provided".to_string())?;
            
            // Validate file type
            let content_type = field.content_type();
            if !self.is_valid_image_type(content_type) {
                return Err(format!("Invalid file type: {:?}", content_type));
            }
            
            // Generate unique filename
            let extension = PathBuf::from(filename)
                .extension()
                .and_then(|s| s.to_str())
                .unwrap_or("jpg")
                .to_string();
            
            let unique_filename = format!("{}_{}.{}", Uuid::new_v4(), filename, extension);
            let filepath = self.upload_dir.join(&unique_filename);
            
            // Save file
            let mut file = web::block(move || std::fs::File::create(filepath))
                .await
                .map_err(|e| e.to_string())?
                .map_err(|e| e.to_string())?;
            
            // Write chunks to file
            while let Some(chunk) = field.next().await {
                let data = chunk.map_err(|e| e.to_string())?;
                file = web::block(move || {
                    let mut f = file;
                    f.write_all(&data)?;
                    Ok::<_, std::io::Error>(f)
                })
                .await
                .map_err(|e| e.to_string())?
                .map_err(|e| e.to_string())?;
            }
            
            // Return URL (in production, this would be a full URL)
            return Ok(format!("/uploads/{}", unique_filename));
        }
        
        Err("No file uploaded".to_string())
    }

    /// Delete a photo by URL
    pub fn delete_photo(&self, photo_url: &str) -> Result<(), String> {
        // Extract filename from URL
        let filename = photo_url
            .split('/')
            .last()
            .ok_or_else(|| "Invalid photo URL".to_string())?;
        
        let filepath = self.upload_dir.join(filename);
        
        if filepath.exists() {
            fs::remove_file(filepath).map_err(|e| e.to_string())?;
        }
        
        Ok(())
    }

    /// Validate image MIME type
    fn is_valid_image_type(&self, content_type: Option<&mime::Mime>) -> bool {
        if let Some(mime) = content_type {
            matches!(
                mime.essence_str(),
                "image/jpeg" | "image/png" | "image/gif" | "image/webp"
            )
        } else {
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_valid_image_type() {
        let service = PhotoService::new("./test_uploads");
        
        assert!(service.is_valid_image_type(Some(&mime::IMAGE_JPEG)));
        assert!(service.is_valid_image_type(Some(&mime::IMAGE_PNG)));
        assert!(service.is_valid_image_type(Some(&mime::IMAGE_GIF)));
        assert!(!service.is_valid_image_type(Some(&mime::TEXT_PLAIN)));
        assert!(!service.is_valid_image_type(None));
    }

    #[test]
    fn test_delete_nonexistent_photo() {
        let service = PhotoService::new("./test_uploads");
        let result = service.delete_photo("/uploads/nonexistent.jpg");
        assert!(result.is_ok()); // Should not error on missing file
    }
}
