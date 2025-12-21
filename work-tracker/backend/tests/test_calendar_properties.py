"""
Property-based tests for calendar integration functionality.

**Property 13: Calendar Integration Workflow**
**Validates: Requirements 8.1, 8.2, 8.3**
"""

import asyncio
from datetime import datetime, timedelta
from typing import List
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock

import pytest
from hypothesis import given, strategies as st, settings, assume
from hypothesis.strategies import composite

from app.models.calendar import CalendarConnection, CalendarEvent, ActivitySuggestion
from app.models.user import User
from app.services.calendar.schemas import (
    CalendarProvider,
    CalendarConnectionStatus,
    CalendarEvent as CalendarEventSchema,
    ActivitySuggestionDecision,
    ActivitySuggestionAction
)
from app.services.calendar.service import CalendarService
from app.services.calendar.ai_service import CalendarAIService


# Test data generators
@composite
def calendar_event_data(draw):
    """Generate calendar event data for testing."""
    title = draw(st.text(min_size=1, max_size=100))
    description = draw(st.text(max_size=500))
    
    # Generate reasonable datetime range
    base_time = datetime(2024, 1, 1, 9, 0)  # 9 AM start
    start_offset_hours = draw(st.integers(min_value=0, max_value=8760))  # Up to 1 year
    duration_hours = draw(st.floats(min_value=0.5, max_value=8.0))  # 30 min to 8 hours
    
    start_time = base_time + timedelta(hours=start_offset_hours)
    end_time = start_time + timedelta(hours=duration_hours)
    
    attendees = draw(st.lists(st.emails(), max_size=10))
    location = draw(st.one_of(st.none(), st.text(max_size=200)))
    meeting_url = draw(st.one_of(st.none(), st.text(max_size=500)))
    organizer = draw(st.one_of(st.none(), st.emails()))
    provider = draw(st.sampled_from(list(CalendarProvider)))
    
    return CalendarEventSchema(
        id=str(uuid4()),
        title=title,
        description=description,
        start_time=start_time,
        end_time=end_time,
        attendees=attendees,
        location=location,
        meeting_url=meeting_url,
        organizer=organizer,
        provider=provider,
        provider_event_id=str(uuid4())
    )


@composite
def calendar_connection_data(draw):
    """Generate calendar connection data for testing."""
    provider = draw(st.sampled_from(list(CalendarProvider)))
    status = draw(st.sampled_from(list(CalendarConnectionStatus)))
    
    return {
        'provider': provider,
        'status': status,
        'access_token': draw(st.one_of(st.none(), st.text(min_size=10, max_size=500))),
        'refresh_token': draw(st.one_of(st.none(), st.text(min_size=10, max_size=500))),
        'provider_user_id': draw(st.one_of(st.none(), st.text(min_size=1, max_size=100))),
        'provider_email': draw(st.one_of(st.none(), st.emails()))
    }


class TestCalendarIntegrationProperties:
    """Property-based tests for calendar integration workflow."""
    
    @given(connection_data=calendar_connection_data())
    @settings(max_examples=50, deadline=30000)
    @pytest.mark.asyncio
    async def test_calendar_connection_lifecycle(
        self, 
        connection_data
    ):
        """
        Property 13a: Calendar Connection Lifecycle
        For any valid calendar connection data, the system should successfully 
        create, retrieve, and manage the connection state.
        **Validates: Requirements 8.1**
        """
        # Create test user
        test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id"
        )
        
        # Mock database session
        mock_db = AsyncMock()
        calendar_service = CalendarService(mock_db)
        
        # Create calendar connection
        connection = CalendarConnection(
            id=uuid4(),
            user_id=test_user.id,
            provider=connection_data['provider'],
            status=connection_data['status'],
            access_token=connection_data['access_token'],
            refresh_token=connection_data['refresh_token'],
            provider_user_id=connection_data['provider_user_id'],
            provider_email=connection_data['provider_email'],
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        # Mock database operations
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=[connection])
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.commit = AsyncMock()
        
        # Verify connection can be retrieved
        connections = await calendar_service.get_user_connections(test_user.id)
        
        # Property: Connection should be retrievable and maintain data integrity
        assert len(connections) >= 1
        found_connection = next(
            (conn for conn in connections if conn.id == connection.id), 
            None
        )
        assert found_connection is not None
        assert found_connection.provider == connection_data['provider']
        assert found_connection.status == connection_data['status']
        
        # Test disconnection
        if connection_data['status'] == CalendarConnectionStatus.CONNECTED:
            # Mock disconnection
            mock_result_disconnect = MagicMock()
            mock_result_disconnect.scalar_one_or_none = MagicMock(return_value=connection)
            mock_db.execute = AsyncMock(return_value=mock_result_disconnect)
            
            success = await calendar_service.disconnect_calendar(test_user.id, connection.id)
            assert success is True
    
    @given(events=st.lists(calendar_event_data(), min_size=1, max_size=10))
    @settings(max_examples=30, deadline=60000)
    @pytest.mark.asyncio
    async def test_calendar_event_processing(
        self,
        events: List[CalendarEventSchema]
    ):
        """
        Property 13b: Calendar Event Processing
        For any collection of calendar events, the system should correctly 
        process and store them while maintaining data consistency.
        **Validates: Requirements 8.1, 8.4**
        """
        # Create test user
        test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id"
        )
        
        # Mock database session
        mock_db = AsyncMock()
        calendar_service = CalendarService(mock_db)
        
        # Create a connected calendar connection
        connection = CalendarConnection(
            id=uuid4(),
            user_id=test_user.id,
            provider=CalendarProvider.GOOGLE,
            status=CalendarConnectionStatus.CONNECTED,
            access_token="test-token",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        # Mock calendar events
        calendar_events = []
        for event_data in events:
            calendar_event = CalendarEvent(
                id=uuid4(),
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
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            calendar_events.append(calendar_event)
        
        # Mock database operations
        mock_connections_result = MagicMock()
        mock_connections_scalars = MagicMock()
        mock_connections_scalars.all = MagicMock(return_value=[connection])
        mock_connections_result.scalars = MagicMock(return_value=mock_connections_scalars)
        
        mock_events_result = MagicMock()
        mock_events_scalars = MagicMock()
        mock_events_scalars.all = MagicMock(return_value=calendar_events)
        mock_events_result.scalars = MagicMock(return_value=mock_events_scalars)
        
        mock_db.execute = AsyncMock(side_effect=[mock_connections_result, mock_events_result])
        
        # Property: All events should be retrievable within their time range
        start_date = min(event.start_time for event in events)
        end_date = max(event.end_time for event in events)
        
        retrieved_events = await calendar_service.get_calendar_events(
            test_user.id, 
            start_date - timedelta(hours=1), 
            end_date + timedelta(hours=1)
        )
        
        # Verify all events are retrieved
        assert len(retrieved_events) == len(events)
        
        # Verify data integrity
        for original_event in events:
            found_event = next(
                (e for e in retrieved_events if e.provider_event_id == original_event.provider_event_id),
                None
            )
            assert found_event is not None
            assert found_event.title == original_event.title
            assert found_event.start_time == original_event.start_time
            assert found_event.end_time == original_event.end_time
    
    @given(events=st.lists(calendar_event_data(), min_size=1, max_size=5))
    @settings(max_examples=20, deadline=90000)
    @pytest.mark.asyncio
    async def test_ai_suggestion_generation(
        self,
        events: List[CalendarEventSchema]
    ):
        """
        Property 13c: AI Suggestion Generation
        For any collection of calendar events, the AI service should generate 
        appropriate activity suggestions that can be processed by users.
        **Validates: Requirements 8.2, 8.3**
        """
        # Filter out events that are too short or have empty titles
        valid_events = [
            event for event in events 
            if event.title.strip() and 
            (event.end_time - event.start_time).total_seconds() >= 900  # At least 15 minutes
        ]
        
        assume(len(valid_events) > 0)
        
        # Create test user
        test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id"
        )
        
        # Mock database session
        mock_db = AsyncMock()
        ai_service = CalendarAIService(mock_db)
        
        # Mock AI response for testing (since we can't call real AI in tests)
        async def mock_generate_single(user_id, event):
            """Mock AI suggestion generation."""
            from app.services.calendar.schemas import ActivitySuggestion
            
            return ActivitySuggestion(
                id=uuid4(),
                event_id=event.id,
                suggested_title=f"Meeting: {event.title}",
                suggested_description=f"Calendar event: {event.title}",
                suggested_category="customer_engagement",
                suggested_tags=["meeting", "calendar"],
                confidence_score=0.8,
                reasoning="Generated from calendar event",
                event_details=event,
                created_at=datetime.utcnow()
            )
        
        ai_service._generate_single_suggestion = mock_generate_single
        
        # Mock database operations for storing suggestions
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        
        # Generate suggestions
        response = await ai_service.generate_activity_suggestions(
            test_user.id, 
            valid_events, 
            suggestion_threshold=0.5
        )
        
        # Property: Suggestions should be generated for valid events
        assert response.total_events_processed == len(valid_events)
        assert response.suggestions_generated >= 0
        assert len(response.suggestions) == response.suggestions_generated
        
        # Property: Each suggestion should have valid data
        for suggestion in response.suggestions:
            assert suggestion.suggested_title.strip()
            assert suggestion.suggested_category in [
                "customer_engagement", "learning", "speaking", 
                "mentoring", "technical_consultation", "content_creation"
            ]
            assert 0.0 <= suggestion.confidence_score <= 1.0
            assert suggestion.reasoning.strip()
            
            # Find corresponding event
            original_event = next(
                (e for e in valid_events if e.id == suggestion.event_id),
                None
            )
            assert original_event is not None
    
    @given(
        action=st.sampled_from(list(ActivitySuggestionAction)),
        modified_title=st.one_of(st.none(), st.text(min_size=1, max_size=100)),
        modified_category=st.one_of(st.none(), st.sampled_from([
            "customer_engagement", "learning", "speaking", 
            "mentoring", "technical_consultation", "content_creation"
        ]))
    )
    @settings(max_examples=30, deadline=60000)
    @pytest.mark.asyncio
    async def test_suggestion_decision_processing(
        self,
        action: ActivitySuggestionAction,
        modified_title: str,
        modified_category: str
    ):
        """
        Property 13d: Suggestion Decision Processing
        For any valid suggestion decision, the system should correctly process 
        the user's choice and update the suggestion status appropriately.
        **Validates: Requirements 8.3**
        """
        # Create test user
        test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id"
        )
        
        # Mock database session
        mock_db = AsyncMock()
        ai_service = CalendarAIService(mock_db)
        
        # Create calendar connection and event
        connection = CalendarConnection(
            id=uuid4(),
            user_id=test_user.id,
            provider=CalendarProvider.GOOGLE,
            status=CalendarConnectionStatus.CONNECTED,
            access_token="test-token",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        calendar_event = CalendarEvent(
            id=uuid4(),
            connection_id=connection.id,
            provider_event_id="test-event-id",
            title="Test Meeting",
            description="Test meeting description",
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow() + timedelta(hours=1),
            attendees=["test@example.com"],
            location="Test Location",
            organizer="organizer@example.com",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        # Create activity suggestion
        suggestion = ActivitySuggestion(
            id=uuid4(),
            connection_id=connection.id,
            calendar_event_id=calendar_event.id,
            user_id=test_user.id,
            suggested_title="Test Activity",
            suggested_description="Test activity description",
            suggested_category="customer_engagement",
            suggested_tags=["test"],
            confidence_score=0.8,
            reasoning="Test suggestion",
            status="pending",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        # Mock database operations
        mock_suggestion_result = MagicMock()
        mock_suggestion_result.scalar_one_or_none = MagicMock(return_value=suggestion)
        
        mock_event_result = MagicMock()
        mock_event_result.scalar_one_or_none = MagicMock(return_value=calendar_event)
        
        mock_db.execute = AsyncMock(side_effect=[mock_suggestion_result, mock_event_result])
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        
        # Mock the activity creation and refresh to set the ID
        created_activity_id = uuid4()
        def mock_refresh(activity):
            activity.id = created_activity_id
        mock_db.refresh = AsyncMock(side_effect=mock_refresh)
        
        # Create decision
        decision = ActivitySuggestionDecision(
            suggestion_id=suggestion.id,
            action=action,
            modified_title=modified_title if action == ActivitySuggestionAction.MODIFY else None,
            modified_category=modified_category if action == ActivitySuggestionAction.MODIFY else None
        )
        
        # Process decision
        response = await ai_service.process_suggestion_decision(test_user.id, decision)
        
        # Property: Decision should be processed correctly
        assert response.suggestion_id == suggestion.id
        assert response.action == action
        assert response.message.strip()
        
        # Verify suggestion status would be updated correctly
        if action == ActivitySuggestionAction.ACCEPT:
            assert response.activity_created is not None
            assert response.activity_created == created_activity_id
        elif action == ActivitySuggestionAction.MODIFY:
            assert response.activity_created is not None
            assert response.activity_created == created_activity_id
        elif action == ActivitySuggestionAction.REJECT:
            assert response.activity_created is None