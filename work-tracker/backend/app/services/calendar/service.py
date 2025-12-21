"""Calendar integration service."""

from datetime import datetime, timedelta
from typing import List, Optional
from uuid import UUID

from sqlalchemy import and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models.calendar import (
    CalendarConnection,
    CalendarEvent,
    ActivitySuggestion,
    CalendarIntegrationSettings
)
from app.models.user import User
from app.services.calendar.oauth_clients import CalendarOAuthClientFactory
from app.services.calendar.schemas import (
    CalendarProvider,
    CalendarConnectionStatus,
    CalendarConnectionCreate,
    CalendarConnectionResponse,
    OAuthAuthorizationUrl,
    CalendarEventSyncRequest,
    CalendarEventSyncResponse,
    ActivitySuggestionResponse,
    ActivitySuggestionDecision,
    ActivitySuggestionDecisionResponse,
    CalendarIntegrationSettingsUpdate,
    CalendarEvent as CalendarEventSchema
)


class CalendarService:
    """Service for calendar integration operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_authorization_url(self, provider: CalendarProvider) -> OAuthAuthorizationUrl:
        """Get OAuth authorization URL for calendar provider."""
        oauth_client = CalendarOAuthClientFactory.create_client(provider)
        authorization_url, state = oauth_client.get_authorization_url()
        
        return OAuthAuthorizationUrl(
            authorization_url=authorization_url,
            state=state
        )
    
    async def create_calendar_connection(
        self, 
        user_id: UUID, 
        connection_data: CalendarConnectionCreate
    ) -> CalendarConnectionResponse:
        """Create a new calendar connection after OAuth authorization."""
        oauth_client = CalendarOAuthClientFactory.create_client(connection_data.provider)
        
        # Exchange authorization code for tokens
        token_data = await oauth_client.exchange_code_for_tokens(
            connection_data.authorization_code,
            ""  # State validation should be done in the router
        )
        
        # Check if connection already exists for this user and provider
        existing_connection = await self.db.execute(
            select(CalendarConnection).where(
                and_(
                    CalendarConnection.user_id == user_id,
                    CalendarConnection.provider == connection_data.provider
                )
            )
        )
        existing = existing_connection.scalar_one_or_none()
        
        if existing:
            # Update existing connection
            existing.status = CalendarConnectionStatus.CONNECTED
            existing.access_token = token_data['access_token']
            existing.refresh_token = token_data.get('refresh_token')
            existing.token_expires_at = token_data.get('expires_at')
            existing.provider_user_id = token_data.get('provider_user_id')
            existing.provider_email = token_data.get('provider_email')
            existing.updated_at = datetime.utcnow()
            
            connection = existing
        else:
            # Create new connection
            connection = CalendarConnection(
                user_id=user_id,
                provider=connection_data.provider,
                status=CalendarConnectionStatus.CONNECTED,
                access_token=token_data['access_token'],
                refresh_token=token_data.get('refresh_token'),
                token_expires_at=token_data.get('expires_at'),
                provider_user_id=token_data.get('provider_user_id'),
                provider_email=token_data.get('provider_email')
            )
            self.db.add(connection)
        
        await self.db.commit()
        await self.db.refresh(connection)
        
        return CalendarConnectionResponse(
            id=connection.id,
            provider=connection.provider,
            status=connection.status,
            provider_email=connection.provider_email,
            created_at=connection.created_at
        )
    
    async def get_user_connections(self, user_id: UUID) -> List[CalendarConnectionResponse]:
        """Get all calendar connections for a user."""
        result = await self.db.execute(
            select(CalendarConnection).where(CalendarConnection.user_id == user_id)
        )
        connections = result.scalars().all()
        
        return [
            CalendarConnectionResponse(
                id=conn.id,
                provider=conn.provider,
                status=conn.status,
                provider_email=conn.provider_email,
                created_at=conn.created_at
            )
            for conn in connections
        ]
    
    async def disconnect_calendar(self, user_id: UUID, connection_id: UUID) -> bool:
        """Disconnect a calendar connection."""
        result = await self.db.execute(
            select(CalendarConnection).where(
                and_(
                    CalendarConnection.id == connection_id,
                    CalendarConnection.user_id == user_id
                )
            )
        )
        connection = result.scalar_one_or_none()
        
        if not connection:
            return False
        
        connection.status = CalendarConnectionStatus.DISCONNECTED
        connection.access_token = None
        connection.refresh_token = None
        connection.token_expires_at = None
        connection.updated_at = datetime.utcnow()
        
        await self.db.commit()
        return True
    
    async def sync_calendar_events(
        self, 
        user_id: UUID, 
        sync_request: CalendarEventSyncRequest
    ) -> CalendarEventSyncResponse:
        """Sync calendar events from a connected calendar."""
        # Get the calendar connection
        result = await self.db.execute(
            select(CalendarConnection).where(
                and_(
                    CalendarConnection.id == sync_request.connection_id,
                    CalendarConnection.user_id == user_id,
                    CalendarConnection.status == CalendarConnectionStatus.CONNECTED
                )
            )
        )
        connection = result.scalar_one_or_none()
        
        if not connection:
            raise ValueError("Calendar connection not found or not connected")
        
        # Check if token needs refresh
        if connection.token_expires_at and connection.token_expires_at <= datetime.utcnow():
            await self._refresh_connection_token(connection)
        
        # Fetch events from calendar provider
        oauth_client = CalendarOAuthClientFactory.create_client(connection.provider)
        calendar_events = await oauth_client.get_calendar_events(
            connection.access_token,
            sync_request.start_date,
            sync_request.end_date
        )
        
        # Store events in database
        events_synced = 0
        for event_data in calendar_events:
            # Check if event already exists
            existing_event = await self.db.execute(
                select(CalendarEvent).where(
                    and_(
                        CalendarEvent.connection_id == connection.id,
                        CalendarEvent.provider_event_id == event_data.provider_event_id
                    )
                )
            )
            existing = existing_event.scalar_one_or_none()
            
            if existing:
                # Update existing event
                existing.title = event_data.title
                existing.description = event_data.description
                existing.start_time = event_data.start_time
                existing.end_time = event_data.end_time
                existing.attendees = event_data.attendees
                existing.location = event_data.location
                existing.meeting_url = event_data.meeting_url
                existing.organizer = event_data.organizer
                existing.last_synced_at = datetime.utcnow()
                existing.updated_at = datetime.utcnow()
            else:
                # Create new event
                new_event = CalendarEvent(
                    connection_id=connection.id,
                    provider_event_id=event_data.provider_event_id,
                    title=event_data.title,
                    description=event_data.description,
                    start_time=event_data.start_time,
                    end_time=event_data.end_time,
                    attendees=event_data.attendees,
                    location=event_data.location,
                    meeting_url=event_data.meeting_url,
                    organizer=event_data.organizer,
                    event_metadata={}
                )
                self.db.add(new_event)
                events_synced += 1
        
        await self.db.commit()
        
        return CalendarEventSyncResponse(
            connection_id=connection.id,
            events_synced=events_synced,
            events=calendar_events,
            sync_timestamp=datetime.utcnow()
        )
    
    async def get_calendar_events(
        self, 
        user_id: UUID, 
        start_date: datetime, 
        end_date: datetime
    ) -> List[CalendarEventSchema]:
        """Get calendar events for a user within a date range."""
        # Get user's calendar connections
        connections_result = await self.db.execute(
            select(CalendarConnection).where(
                and_(
                    CalendarConnection.user_id == user_id,
                    CalendarConnection.status == CalendarConnectionStatus.CONNECTED
                )
            )
        )
        connections = connections_result.scalars().all()
        
        if not connections:
            return []
        
        connection_ids = [conn.id for conn in connections]
        
        # Get events from all connections
        events_result = await self.db.execute(
            select(CalendarEvent).where(
                and_(
                    CalendarEvent.connection_id.in_(connection_ids),
                    CalendarEvent.start_time >= start_date,
                    CalendarEvent.end_time <= end_date
                )
            ).order_by(CalendarEvent.start_time)
        )
        events = events_result.scalars().all()
        
        # Convert to schema objects
        calendar_events = []
        for event in events:
            connection = next(conn for conn in connections if conn.id == event.connection_id)
            calendar_event = CalendarEventSchema(
                id=str(event.id),
                title=event.title,
                description=event.description,
                start_time=event.start_time,
                end_time=event.end_time,
                attendees=event.attendees,
                location=event.location,
                meeting_url=event.meeting_url,
                organizer=event.organizer,
                provider=connection.provider,
                provider_event_id=event.provider_event_id
            )
            calendar_events.append(calendar_event)
        
        return calendar_events
    
    async def get_integration_settings(self, user_id: UUID) -> CalendarIntegrationSettings:
        """Get calendar integration settings for a user."""
        result = await self.db.execute(
            select(CalendarIntegrationSettings).where(
                CalendarIntegrationSettings.user_id == user_id
            )
        )
        settings = result.scalar_one_or_none()
        
        if not settings:
            # Create default settings
            settings = CalendarIntegrationSettings(user_id=user_id)
            self.db.add(settings)
            await self.db.commit()
            await self.db.refresh(settings)
        
        return settings
    
    async def update_integration_settings(
        self, 
        user_id: UUID, 
        settings_update: CalendarIntegrationSettingsUpdate
    ) -> CalendarIntegrationSettings:
        """Update calendar integration settings for a user."""
        settings = await self.get_integration_settings(user_id)
        
        # Update fields that are provided
        update_data = settings_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(settings, field, value)
        
        settings.updated_at = datetime.utcnow()
        await self.db.commit()
        await self.db.refresh(settings)
        
        return settings
    
    async def _refresh_connection_token(self, connection: CalendarConnection) -> None:
        """Refresh access token for a calendar connection."""
        if not connection.refresh_token:
            connection.status = CalendarConnectionStatus.EXPIRED
            await self.db.commit()
            return
        
        try:
            oauth_client = CalendarOAuthClientFactory.create_client(connection.provider)
            token_data = await oauth_client.refresh_access_token(connection.refresh_token)
            
            connection.access_token = token_data['access_token']
            connection.token_expires_at = token_data.get('expires_at')
            connection.updated_at = datetime.utcnow()
            
            await self.db.commit()
        except Exception:
            connection.status = CalendarConnectionStatus.ERROR
            await self.db.commit()


async def get_calendar_service(db: AsyncSession = None) -> CalendarService:
    """Get calendar service instance."""
    if db is None:
        async for db_session in get_db():
            return CalendarService(db_session)
    return CalendarService(db)