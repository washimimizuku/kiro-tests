"""Calendar integration API routes."""

from datetime import datetime, timedelta
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.services.auth.jwt_middleware import get_current_user
from app.services.calendar.service import CalendarService
from app.services.calendar.ai_service import CalendarAIService
from app.services.calendar.schemas import (
    CalendarProvider,
    CalendarConnectionCreate,
    CalendarConnectionResponse,
    OAuthAuthorizationUrl,
    CalendarEventSyncRequest,
    CalendarEventSyncResponse,
    CalendarEvent,
    CalendarIntegrationSettings,
    CalendarIntegrationSettingsUpdate,
    ActivitySuggestion,
    ActivitySuggestionResponse,
    ActivitySuggestionDecision,
    ActivitySuggestionDecisionResponse
)
from app.models.user import User

router = APIRouter(prefix="/calendar", tags=["calendar"])


@router.get("/oauth/{provider}/authorize", response_model=OAuthAuthorizationUrl)
async def get_oauth_authorization_url(
    provider: CalendarProvider,
    db: AsyncSession = Depends(get_db)
):
    """Get OAuth authorization URL for calendar provider."""
    service = CalendarService(db)
    
    try:
        return await service.get_authorization_url(provider)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get authorization URL: {str(e)}"
        )


@router.post("/oauth/{provider}/callback", response_model=CalendarConnectionResponse)
async def oauth_callback(
    provider: CalendarProvider,
    connection_data: CalendarConnectionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Handle OAuth callback and create calendar connection."""
    if connection_data.provider != provider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provider mismatch"
        )
    
    service = CalendarService(db)
    
    try:
        return await service.create_calendar_connection(current_user.id, connection_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create calendar connection: {str(e)}"
        )


@router.get("/connections", response_model=List[CalendarConnectionResponse])
async def get_calendar_connections(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all calendar connections for the current user."""
    service = CalendarService(db)
    return await service.get_user_connections(current_user.id)


@router.delete("/connections/{connection_id}")
async def disconnect_calendar(
    connection_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Disconnect a calendar connection."""
    service = CalendarService(db)
    
    success = await service.disconnect_calendar(current_user.id, connection_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Calendar connection not found"
        )
    
    return {"message": "Calendar disconnected successfully"}


@router.post("/sync", response_model=CalendarEventSyncResponse)
async def sync_calendar_events(
    sync_request: CalendarEventSyncRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Sync calendar events from a connected calendar."""
    service = CalendarService(db)
    
    try:
        return await service.sync_calendar_events(current_user.id, sync_request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to sync calendar events: {str(e)}"
        )


@router.get("/events", response_model=List[CalendarEvent])
async def get_calendar_events(
    start_date: datetime = Query(..., description="Start date for event range"),
    end_date: datetime = Query(..., description="End date for event range"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get calendar events for the current user within a date range."""
    if end_date <= start_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="End date must be after start date"
        )
    
    # Limit range to prevent excessive data
    max_range = timedelta(days=90)
    if end_date - start_date > max_range:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Date range cannot exceed 90 days"
        )
    
    service = CalendarService(db)
    return await service.get_calendar_events(current_user.id, start_date, end_date)


@router.get("/settings", response_model=CalendarIntegrationSettings)
async def get_integration_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get calendar integration settings for the current user."""
    service = CalendarService(db)
    return await service.get_integration_settings(current_user.id)


@router.put("/settings", response_model=CalendarIntegrationSettings)
async def update_integration_settings(
    settings_update: CalendarIntegrationSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update calendar integration settings for the current user."""
    service = CalendarService(db)
    return await service.update_integration_settings(current_user.id, settings_update)


@router.post("/suggestions/generate", response_model=ActivitySuggestionResponse)
async def generate_activity_suggestions(
    start_date: datetime = Query(..., description="Start date for events to analyze"),
    end_date: datetime = Query(..., description="End date for events to analyze"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate AI-powered activity suggestions from calendar events."""
    if end_date <= start_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="End date must be after start date"
        )
    
    # Limit range to prevent excessive processing
    max_range = timedelta(days=30)
    if end_date - start_date > max_range:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Date range cannot exceed 30 days"
        )
    
    try:
        # Get calendar events
        calendar_service = CalendarService(db)
        events = await calendar_service.get_calendar_events(current_user.id, start_date, end_date)
        
        # Get user settings for threshold
        settings = await calendar_service.get_integration_settings(current_user.id)
        
        # Generate suggestions
        ai_service = CalendarAIService(db)
        return await ai_service.generate_activity_suggestions(
            current_user.id, 
            events, 
            settings.suggestion_threshold
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate activity suggestions: {str(e)}"
        )


@router.get("/suggestions", response_model=List[ActivitySuggestion])
async def get_pending_suggestions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all pending activity suggestions for the current user."""
    ai_service = CalendarAIService(db)
    return await ai_service.get_pending_suggestions(current_user.id)


@router.post("/suggestions/{suggestion_id}/decide", response_model=ActivitySuggestionDecisionResponse)
async def process_suggestion_decision(
    suggestion_id: UUID,
    decision: ActivitySuggestionDecision,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Process user decision on an activity suggestion."""
    # Ensure the suggestion_id matches
    if decision.suggestion_id != suggestion_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Suggestion ID mismatch"
        )
    
    try:
        ai_service = CalendarAIService(db)
        return await ai_service.process_suggestion_decision(current_user.id, decision)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process suggestion decision: {str(e)}"
        )