"""Calendar integration database models."""

from datetime import datetime
from typing import Dict, List, Optional
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    Float,
    JSON,
)
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID, ARRAY
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base
from app.services.calendar.schemas import CalendarProvider, CalendarConnectionStatus


class CalendarConnection(Base):
    """Calendar connection model."""
    
    __tablename__ = "calendar_connections"
    
    id = Column(PostgresUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(PostgresUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    provider = Column(Enum(CalendarProvider), nullable=False)
    status = Column(Enum(CalendarConnectionStatus), nullable=False, default=CalendarConnectionStatus.DISCONNECTED)
    access_token = Column(Text, nullable=True)
    refresh_token = Column(Text, nullable=True)
    token_expires_at = Column(DateTime(timezone=True), nullable=True)
    provider_user_id = Column(String(255), nullable=True)
    provider_email = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="calendar_connections")
    calendar_events = relationship("CalendarEvent", back_populates="connection", cascade="all, delete-orphan")
    activity_suggestions = relationship("ActivitySuggestion", back_populates="connection", cascade="all, delete-orphan")


class CalendarEvent(Base):
    """Calendar event model."""
    
    __tablename__ = "calendar_events"
    
    id = Column(PostgresUUID(as_uuid=True), primary_key=True, default=uuid4)
    connection_id = Column(PostgresUUID(as_uuid=True), ForeignKey("calendar_connections.id", ondelete="CASCADE"), nullable=False)
    provider_event_id = Column(String(255), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    attendees = Column(ARRAY(String), nullable=False, default=[])
    location = Column(String(500), nullable=True)
    meeting_url = Column(Text, nullable=True)
    organizer = Column(String(255), nullable=True)
    event_metadata = Column(JSON, nullable=False, default={})
    last_synced_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    connection = relationship("CalendarConnection", back_populates="calendar_events")
    activity_suggestions = relationship("ActivitySuggestion", back_populates="calendar_event", cascade="all, delete-orphan")


class ActivitySuggestion(Base):
    """Activity suggestion model."""
    
    __tablename__ = "activity_suggestions"
    
    id = Column(PostgresUUID(as_uuid=True), primary_key=True, default=uuid4)
    connection_id = Column(PostgresUUID(as_uuid=True), ForeignKey("calendar_connections.id", ondelete="CASCADE"), nullable=False)
    calendar_event_id = Column(PostgresUUID(as_uuid=True), ForeignKey("calendar_events.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(PostgresUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    suggested_title = Column(String(500), nullable=False)
    suggested_description = Column(Text, nullable=True)
    suggested_category = Column(String(100), nullable=False)
    suggested_tags = Column(ARRAY(String), nullable=False, default=[])
    confidence_score = Column(Float, nullable=False)
    reasoning = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, accepted, rejected, modified
    activity_id = Column(PostgresUUID(as_uuid=True), ForeignKey("activities.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    connection = relationship("CalendarConnection", back_populates="activity_suggestions")
    calendar_event = relationship("CalendarEvent", back_populates="activity_suggestions")
    user = relationship("User", back_populates="activity_suggestions")
    activity = relationship("Activity", back_populates="activity_suggestions")


class CalendarIntegrationSettings(Base):
    """Calendar integration settings model."""
    
    __tablename__ = "calendar_integration_settings"
    
    id = Column(PostgresUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(PostgresUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    auto_sync_enabled = Column(Boolean, nullable=False, default=True)
    sync_frequency_hours = Column(Integer, nullable=False, default=24)
    suggestion_threshold = Column(Float, nullable=False, default=0.7)
    excluded_calendars = Column(ARRAY(String), nullable=False, default=[])
    excluded_keywords = Column(ARRAY(String), nullable=False, default=[])
    include_declined_events = Column(Boolean, nullable=False, default=False)
    include_all_day_events = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="calendar_settings")