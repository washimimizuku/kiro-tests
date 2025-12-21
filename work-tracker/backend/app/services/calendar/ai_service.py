"""AI service for calendar-based activity suggestions."""

import json
from datetime import datetime
from typing import List, Dict, Any
from uuid import UUID, uuid4

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.models.calendar import ActivitySuggestion as ActivitySuggestionModel, CalendarEvent
from app.models.activity import ActivityCategory
from app.services.ai.bedrock_client import BedrockClient
from app.services.calendar.schemas import (
    CalendarEvent as CalendarEventSchema,
    ActivitySuggestion,
    ActivitySuggestionResponse,
    ActivitySuggestionDecision,
    ActivitySuggestionDecisionResponse,
    ActivitySuggestionAction
)
from app.models.activity import Activity
from app.schemas.activity import ActivityCreate


class CalendarAIService:
    """AI service for generating activity suggestions from calendar events."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.bedrock_client = BedrockClient()
    
    async def generate_activity_suggestions(
        self, 
        user_id: UUID, 
        calendar_events: List[CalendarEventSchema],
        suggestion_threshold: float = 0.7
    ) -> ActivitySuggestionResponse:
        """Generate AI-powered activity suggestions from calendar events."""
        suggestions = []
        total_events = len(calendar_events)
        
        for event in calendar_events:
            try:
                suggestion = await self._generate_single_suggestion(user_id, event)
                
                # Only include suggestions above the threshold
                if suggestion and suggestion.confidence_score >= suggestion_threshold:
                    suggestions.append(suggestion)
                    
                    # Store suggestion in database
                    await self._store_suggestion(suggestion, event)
                    
            except Exception as e:
                # Log error but continue processing other events
                print(f"Error generating suggestion for event {event.id}: {str(e)}")
                continue
        
        return ActivitySuggestionResponse(
            suggestions=suggestions,
            total_events_processed=total_events,
            suggestions_generated=len(suggestions)
        )
    
    async def _generate_single_suggestion(
        self, 
        user_id: UUID, 
        event: CalendarEventSchema
    ) -> ActivitySuggestion:
        """Generate a single activity suggestion from a calendar event."""
        
        # Create prompt for AI
        prompt = self._create_suggestion_prompt(event)
        
        # Get AI response
        ai_response = await self.bedrock_client.generate_text(
            prompt=prompt,
            max_tokens=500,
            temperature=0.3
        )
        
        # Parse AI response
        suggestion_data = self._parse_ai_response(ai_response)
        
        if not suggestion_data:
            return None
        
        # Create suggestion object
        suggestion = ActivitySuggestion(
            id=uuid4(),
            event_id=event.id,
            suggested_title=suggestion_data.get('title', event.title),
            suggested_description=suggestion_data.get('description', ''),
            suggested_category=suggestion_data.get('category', ActivityCategory.CUSTOMER_ENGAGEMENT.value),
            suggested_tags=suggestion_data.get('tags', []),
            confidence_score=suggestion_data.get('confidence', 0.5),
            reasoning=suggestion_data.get('reasoning', ''),
            event_details=event,
            created_at=datetime.utcnow()
        )
        
        return suggestion
    
    def _create_suggestion_prompt(self, event: CalendarEventSchema) -> str:
        """Create AI prompt for activity suggestion generation."""
        
        # Format attendees
        attendees_str = ", ".join(event.attendees) if event.attendees else "No attendees listed"
        
        # Format time
        duration = (event.end_time - event.start_time).total_seconds() / 3600  # hours
        
        prompt = f"""
You are an AI assistant helping a professional track their work activities. Based on the following calendar event, suggest how it should be categorized as a professional activity.

Calendar Event Details:
- Title: {event.title}
- Description: {event.description or "No description"}
- Start Time: {event.start_time.strftime('%Y-%m-%d %H:%M')}
- End Time: {event.end_time.strftime('%Y-%m-%d %H:%M')}
- Duration: {duration:.1f} hours
- Location: {event.location or "No location specified"}
- Attendees: {attendees_str}
- Meeting URL: {event.meeting_url or "No meeting URL"}
- Organizer: {event.organizer or "Unknown organizer"}

Available Activity Categories:
- customer_engagement: Direct interactions with customers, client meetings, support calls
- learning: Training sessions, workshops, courses, conferences, skill development
- speaking: Presentations, talks, webinars, public speaking engagements
- mentoring: Coaching others, knowledge sharing, team guidance
- technical_consultation: Technical discussions, architecture reviews, code reviews
- content_creation: Writing, documentation, blog posts, creating materials

Please analyze this event and provide a JSON response with the following structure:
{{
    "title": "Suggested activity title (concise and professional)",
    "description": "Brief description of what was accomplished or discussed",
    "category": "one of the available categories above",
    "tags": ["relevant", "tags", "for", "this", "activity"],
    "confidence": 0.0-1.0 (how confident you are in this categorization),
    "reasoning": "Brief explanation of why you chose this categorization"
}}

Guidelines:
- If the event seems personal or not work-related, set confidence to 0.0
- For recurring meetings without clear purpose, use lower confidence (0.3-0.5)
- For clearly work-related events with specific outcomes, use higher confidence (0.7-1.0)
- Keep titles concise but descriptive
- Include relevant tags like company names, project names, technologies, etc.
- Focus on professional value and impact

Respond only with valid JSON, no additional text.
"""
        
        return prompt
    
    def _parse_ai_response(self, ai_response: str) -> Dict[str, Any]:
        """Parse AI response into structured data."""
        try:
            # Clean up the response - remove any markdown formatting
            cleaned_response = ai_response.strip()
            if cleaned_response.startswith('```json'):
                cleaned_response = cleaned_response[7:]
            if cleaned_response.endswith('```'):
                cleaned_response = cleaned_response[:-3]
            cleaned_response = cleaned_response.strip()
            
            # Parse JSON
            data = json.loads(cleaned_response)
            
            # Validate required fields
            required_fields = ['title', 'category', 'confidence']
            for field in required_fields:
                if field not in data:
                    return None
            
            # Validate category
            valid_categories = [cat.value for cat in ActivityCategory]
            if data['category'] not in valid_categories:
                data['category'] = ActivityCategory.CUSTOMER_ENGAGEMENT.value
            
            # Ensure confidence is in valid range
            confidence = float(data['confidence'])
            data['confidence'] = max(0.0, min(1.0, confidence))
            
            # Ensure tags is a list
            if 'tags' not in data:
                data['tags'] = []
            elif not isinstance(data['tags'], list):
                data['tags'] = []
            
            # Ensure description exists
            if 'description' not in data:
                data['description'] = ''
            
            # Ensure reasoning exists
            if 'reasoning' not in data:
                data['reasoning'] = 'AI-generated suggestion based on calendar event analysis'
            
            return data
            
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            print(f"Error parsing AI response: {str(e)}")
            return None
    
    async def _store_suggestion(self, suggestion: ActivitySuggestion, event: CalendarEventSchema) -> None:
        """Store activity suggestion in database."""
        
        # Find the calendar event in database
        event_result = await self.db.execute(
            select(CalendarEvent).where(CalendarEvent.provider_event_id == event.provider_event_id)
        )
        calendar_event = event_result.scalar_one_or_none()
        
        if not calendar_event:
            return
        
        # Create database model
        suggestion_model = ActivitySuggestionModel(
            id=suggestion.id,
            connection_id=calendar_event.connection_id,
            calendar_event_id=calendar_event.id,
            user_id=calendar_event.connection.user_id,
            suggested_title=suggestion.suggested_title,
            suggested_description=suggestion.suggested_description,
            suggested_category=suggestion.suggested_category,
            suggested_tags=suggestion.suggested_tags,
            confidence_score=suggestion.confidence_score,
            reasoning=suggestion.reasoning,
            status="pending"
        )
        
        self.db.add(suggestion_model)
        await self.db.commit()
    
    async def get_pending_suggestions(self, user_id: UUID) -> List[ActivitySuggestion]:
        """Get all pending activity suggestions for a user."""
        
        result = await self.db.execute(
            select(ActivitySuggestionModel)
            .where(
                ActivitySuggestionModel.user_id == user_id,
                ActivitySuggestionModel.status == "pending"
            )
            .order_by(ActivitySuggestionModel.created_at.desc())
        )
        
        suggestions = result.scalars().all()
        
        # Convert to schema objects
        suggestion_list = []
        for suggestion in suggestions:
            # Get calendar event details
            event_result = await self.db.execute(
                select(CalendarEvent).where(CalendarEvent.id == suggestion.calendar_event_id)
            )
            calendar_event = event_result.scalar_one_or_none()
            
            if calendar_event:
                event_schema = CalendarEventSchema(
                    id=str(calendar_event.id),
                    title=calendar_event.title,
                    description=calendar_event.description,
                    start_time=calendar_event.start_time,
                    end_time=calendar_event.end_time,
                    attendees=calendar_event.attendees,
                    location=calendar_event.location,
                    meeting_url=calendar_event.meeting_url,
                    organizer=calendar_event.organizer,
                    provider=calendar_event.connection.provider,
                    provider_event_id=calendar_event.provider_event_id
                )
                
                suggestion_schema = ActivitySuggestion(
                    id=suggestion.id,
                    event_id=str(calendar_event.id),
                    suggested_title=suggestion.suggested_title,
                    suggested_description=suggestion.suggested_description,
                    suggested_category=suggestion.suggested_category,
                    suggested_tags=suggestion.suggested_tags,
                    confidence_score=suggestion.confidence_score,
                    reasoning=suggestion.reasoning,
                    event_details=event_schema,
                    created_at=suggestion.created_at
                )
                
                suggestion_list.append(suggestion_schema)
        
        return suggestion_list
    
    async def process_suggestion_decision(
        self, 
        user_id: UUID, 
        decision: ActivitySuggestionDecision
    ) -> ActivitySuggestionDecisionResponse:
        """Process user decision on an activity suggestion."""
        
        # Get the suggestion
        result = await self.db.execute(
            select(ActivitySuggestionModel)
            .where(
                ActivitySuggestionModel.id == decision.suggestion_id,
                ActivitySuggestionModel.user_id == user_id
            )
        )
        suggestion = result.scalar_one_or_none()
        
        if not suggestion:
            raise ValueError("Suggestion not found")
        
        activity_id = None
        message = ""
        
        if decision.action == ActivitySuggestionAction.ACCEPT:
            # Create activity from suggestion
            activity_id = await self._create_activity_from_suggestion(user_id, suggestion)
            suggestion.status = "accepted"
            suggestion.activity_id = activity_id
            message = "Activity created successfully from suggestion"
            
        elif decision.action == ActivitySuggestionAction.MODIFY:
            # Create activity with modifications
            activity_id = await self._create_activity_from_suggestion(
                user_id, suggestion, decision
            )
            suggestion.status = "modified"
            suggestion.activity_id = activity_id
            message = "Activity created with modifications"
            
        elif decision.action == ActivitySuggestionAction.REJECT:
            suggestion.status = "rejected"
            message = "Suggestion rejected"
        
        suggestion.updated_at = datetime.utcnow()
        await self.db.commit()
        
        return ActivitySuggestionDecisionResponse(
            suggestion_id=decision.suggestion_id,
            action=decision.action,
            activity_created=activity_id,
            message=message
        )
    
    async def _create_activity_from_suggestion(
        self, 
        user_id: UUID, 
        suggestion: ActivitySuggestionModel,
        modifications: ActivitySuggestionDecision = None
    ) -> UUID:
        """Create an activity from a suggestion."""
        
        # Get calendar event for date
        event_result = await self.db.execute(
            select(CalendarEvent).where(CalendarEvent.id == suggestion.calendar_event_id)
        )
        calendar_event = event_result.scalar_one_or_none()
        
        if not calendar_event:
            raise ValueError("Calendar event not found")
        
        # Use modifications if provided, otherwise use suggestion
        title = modifications.modified_title if modifications and modifications.modified_title else suggestion.suggested_title
        description = modifications.modified_description if modifications and modifications.modified_description else suggestion.suggested_description
        category = modifications.modified_category if modifications and modifications.modified_category else suggestion.suggested_category
        tags = modifications.modified_tags if modifications and modifications.modified_tags else suggestion.suggested_tags
        
        # Calculate duration in minutes
        duration_minutes = int((calendar_event.end_time - calendar_event.start_time).total_seconds() / 60)
        
        # Create activity
        activity = Activity(
            user_id=user_id,
            title=title,
            description=description,
            category=category,
            tags=tags or [],
            impact_level=3,  # Default impact level
            date=calendar_event.start_time.date(),
            duration_minutes=duration_minutes,
            metadata_json={
                "source": "calendar_suggestion",
                "calendar_event_id": str(calendar_event.id),
                "suggestion_id": str(suggestion.id),
                "meeting_url": calendar_event.meeting_url,
                "location": calendar_event.location,
                "attendees": calendar_event.attendees
            }
        )
        
        self.db.add(activity)
        await self.db.commit()
        await self.db.refresh(activity)
        
        return activity.id