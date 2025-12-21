"""
API v1 Router

Main router that includes all API endpoints for version 1.
Organizes routes by service domain (auth, activities, stories, reports, ai).
"""

from fastapi import APIRouter

# Import service routers
from app.services.auth.router import router as auth_router
from app.services.activities.router import router as activities_router
from app.services.stories.router import router as stories_router
from app.services.ai.router import router as ai_router
from app.services.reports.router import router as reports_router
from app.services.export.router import router as export_router
from app.services.calendar.router import router as calendar_router

# Create main API router
api_router = APIRouter()

# Health check for API
@api_router.get("/health")
async def api_health():
    """API health check endpoint."""
    return {
        "status": "healthy",
        "api_version": "v1",
        "services": {
            "auth": "healthy",
            "activities": "healthy", 
            "stories": "healthy",
            "ai": "healthy",
            "reports": "healthy",
            "export": "healthy",
            "calendar": "healthy",
        }
    }

# Include service routers
api_router.include_router(auth_router, prefix="/auth", tags=["authentication"])
api_router.include_router(activities_router, prefix="/activities", tags=["activities"])
api_router.include_router(stories_router, prefix="/stories", tags=["stories"])
api_router.include_router(ai_router, prefix="/ai", tags=["ai"])
api_router.include_router(reports_router, prefix="/reports", tags=["reports"])
api_router.include_router(export_router, prefix="/export", tags=["export"])
api_router.include_router(calendar_router, prefix="/calendar", tags=["calendar"])