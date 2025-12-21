"""Calendar integration schemas."""

from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class CalendarProvider(str, Enum):
    """Supported calendar providers."""
    GOOGLE = "google"
    OUTLOOK = "outlook"


class CalendarConnectionStatus(str, Enum):
    """Calendar connection status."""
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    ERROR = "error"
    EXPIRED = "expired"


class CalendarConnection(BaseModel):
    """Calendar connection model."""
    id: UUID
    user_id: UUID
    provider: CalendarProvider
    status: CalendarConnectionStatus
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_expires_at: Optional[datetime] = None
    provider_user_id: Optional[str] = None
    provider_email: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class CalendarConnectionCreate(BaseModel):
    """Schema for creating calendar connection."""
    provider: CalendarProvider
    authorization_code: str
    redirect_uri: str


class CalendarConnectionResponse(BaseModel):
    """Response schema for calendar connection."""
    id: UUID
    provider: CalendarProvider
    status: CalendarConnectionStatus
    provider_email: Optional[str] = None
    created_at: datetime


class OAuthAuthorizationUrl(BaseModel):
    """OAuth authorization URL response."""
    authorization_url: str
    state: str


class CalendarEvent(BaseModel):
    """Calendar event model."""
    id: str
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    attendees: List[str] = Field(default_factory=list)
    location: Optional[str] = None
    meeting_url: Optional[str] = None
    organizer: Optional[str] = None
    provider: CalendarProvider
    provider_event_id: str


class CalendarEventSyncRequest(BaseModel):
    """Request to sync calendar events."""
    connection_id: UUID
    start_date: datetime
    end_date: datetime


class CalendarEventSyncResponse(BaseModel):
    """Response from calendar event sync."""
    connection_id: UUID
    events_synced: int
    events: List[CalendarEvent]
    sync_timestamp: datetime


class ActivitySuggestion(BaseModel):
    """AI-generated activity suggestion from calendar event."""
    id: UUID
    event_id: str
    suggested_title: str
    suggested_description: str
    suggested_category: str
    suggested_tags: List[str] = Field(default_factory=list)
    confidence_score: float = Field(ge=0.0, le=1.0)
    reasoning: str
    event_details: CalendarEvent
    created_at: datetime


class ActivitySuggestionResponse(BaseModel):
    """Response containing activity suggestions."""
    suggestions: List[ActivitySuggestion]
    total_events_processed: int
    suggestions_generated: int


class ActivitySuggestionAction(str, Enum):
    """Actions for activity suggestions."""
    ACCEPT = "accept"
    MODIFY = "modify"
    REJECT = "reject"


class ActivitySuggestionDecision(BaseModel):
    """User decision on activity suggestion."""
    suggestion_id: UUID
    action: ActivitySuggestionAction
    modified_title: Optional[str] = None
    modified_description: Optional[str] = None
    modified_category: Optional[str] = None
    modified_tags: Optional[List[str]] = None


class ActivitySuggestionDecisionResponse(BaseModel):
    """Response to activity suggestion decision."""
    suggestion_id: UUID
    action: ActivitySuggestionAction
    activity_created: Optional[UUID] = None
    message: str


class CalendarIntegrationSettings(BaseModel):
    """User settings for calendar integration."""
    user_id: UUID
    auto_sync_enabled: bool = True
    sync_frequency_hours: int = Field(default=24, ge=1, le=168)  # 1 hour to 1 week
    suggestion_threshold: float = Field(default=0.7, ge=0.0, le=1.0)
    excluded_calendars: List[str] = Field(default_factory=list)
    excluded_keywords: List[str] = Field(default_factory=list)
    include_declined_events: bool = False
    include_all_day_events: bool = False


class CalendarIntegrationSettingsUpdate(BaseModel):
    """Schema for updating calendar integration settings."""
    auto_sync_enabled: Optional[bool] = None
    sync_frequency_hours: Optional[int] = Field(None, ge=1, le=168)
    suggestion_threshold: Optional[float] = Field(None, ge=0.0, le=1.0)
    excluded_calendars: Optional[List[str]] = None
    excluded_keywords: Optional[List[str]] = None
    include_declined_events: Optional[bool] = None
    include_all_day_events: Optional[bool] = None