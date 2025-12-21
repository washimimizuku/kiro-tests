"""
Unit Tests for Data Models

Tests model validation, relationships, and schema serialization/deserialization.
"""

import pytest
from datetime import date, datetime
from uuid import uuid4

from app.models import User, Activity, ActivityCategory, Story, StoryStatus, Report, ReportType, ReportStatus
from app.schemas import (
    UserCreate, UserResponse, ActivityCreate, ActivityResponse, 
    StoryCreate, StoryResponse, ReportCreate, ReportResponse
)


class TestUserModel:
    """Unit tests for User model and schemas."""
    
    def test_user_model_creation(self):
        """Test User model creation with valid data."""
        user_data = {
            "id": uuid4(),
            "email": "test@example.com",
            "name": "Test User",
            "cognito_user_id": "cognito-123",
            "preferences": {"theme": "dark"},
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        
        user = User(**user_data)
        
        assert user.email == "test@example.com"
        assert user.name == "Test User"
        assert user.cognito_user_id == "cognito-123"
        assert user.preferences == {"theme": "dark"}
    
    def test_user_create_schema_validation(self):
        """Test UserCreate schema validation."""
        user_data = {
            "email": "test@example.com",
            "name": "Test User",
            "cognito_user_id": "cognito-123",
            "preferences": {"theme": "dark"}
        }
        
        user_create = UserCreate(**user_data)
        
        assert user_create.email == "test@example.com"
        assert user_create.name == "Test User"
        assert user_create.cognito_user_id == "cognito-123"
        assert user_create.preferences == {"theme": "dark"}
    
    def test_user_create_schema_invalid_email(self):
        """Test UserCreate schema with invalid email."""
        user_data = {
            "email": "invalid-email",
            "name": "Test User",
            "cognito_user_id": "cognito-123"
        }
        
        with pytest.raises(ValueError):
            UserCreate(**user_data)
    
    def test_user_create_schema_empty_name(self):
        """Test UserCreate schema with empty name."""
        user_data = {
            "email": "test@example.com",
            "name": "",
            "cognito_user_id": "cognito-123"
        }
        
        with pytest.raises(ValueError):
            UserCreate(**user_data)


class TestActivityModel:
    """Unit tests for Activity model and schemas."""
    
    def test_activity_model_creation(self):
        """Test Activity model creation with valid data."""
        activity_data = {
            "id": uuid4(),
            "user_id": uuid4(),
            "title": "Customer Meeting",
            "description": "Discussed project requirements",
            "category": ActivityCategory.CUSTOMER_ENGAGEMENT.value,
            "tags": ["meeting", "requirements"],
            "impact_level": 4,
            "date": date.today(),
            "duration_minutes": 60,
            "metadata": {"location": "office"},
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        
        activity = Activity(**activity_data)
        
        assert activity.title == "Customer Meeting"
        assert activity.category == ActivityCategory.CUSTOMER_ENGAGEMENT.value
        assert activity.impact_level == 4
        assert activity.tags == ["meeting", "requirements"]
    
    def test_activity_create_schema_validation(self):
        """Test ActivityCreate schema validation."""
        activity_data = {
            "title": "Customer Meeting",
            "description": "Discussed project requirements",
            "category": ActivityCategory.CUSTOMER_ENGAGEMENT,
            "tags": ["meeting", "requirements"],
            "impact_level": 4,
            "date": date.today(),
            "duration_minutes": 60,
            "metadata": {"location": "office"}
        }
        
        activity_create = ActivityCreate(**activity_data)
        
        assert activity_create.title == "Customer Meeting"
        assert activity_create.category == ActivityCategory.CUSTOMER_ENGAGEMENT
        assert activity_create.impact_level == 4
        assert activity_create.tags == ["meeting", "requirements"]
    
    def test_activity_create_schema_invalid_impact_level(self):
        """Test ActivityCreate schema with invalid impact level."""
        activity_data = {
            "title": "Customer Meeting",
            "category": ActivityCategory.CUSTOMER_ENGAGEMENT,
            "impact_level": 6,  # Invalid: should be 1-5
            "date": date.today()
        }
        
        with pytest.raises(ValueError):
            ActivityCreate(**activity_data)
    
    def test_activity_create_schema_negative_duration(self):
        """Test ActivityCreate schema with negative duration."""
        activity_data = {
            "title": "Customer Meeting",
            "category": ActivityCategory.CUSTOMER_ENGAGEMENT,
            "date": date.today(),
            "duration_minutes": -30  # Invalid: should be >= 0
        }
        
        with pytest.raises(ValueError):
            ActivityCreate(**activity_data)
    
    def test_activity_serialization_deserialization(self):
        """Test Activity model to schema serialization and back."""
        # Create activity model
        activity = Activity(
            id=uuid4(),
            user_id=uuid4(),
            title="Test Activity",
            description="Test description",
            category=ActivityCategory.LEARNING.value,
            tags=["test"],
            impact_level=3,
            date=date.today(),
            duration_minutes=30,
            metadata={"test": "data"},
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        # Convert to response schema
        response_dict = {
            "id": activity.id,
            "user_id": activity.user_id,
            "title": activity.title,
            "description": activity.description,
            "category": ActivityCategory(activity.category),
            "tags": activity.tags,
            "impact_level": activity.impact_level,
            "date": activity.date,
            "duration_minutes": activity.duration_minutes,
            "metadata": activity.metadata,
            "created_at": activity.created_at,
            "updated_at": activity.updated_at,
        }
        
        response = ActivityResponse(**response_dict)
        
        # Verify data integrity
        assert response.title == activity.title
        assert response.category.value == activity.category
        assert response.impact_level == activity.impact_level


class TestStoryModel:
    """Unit tests for Story model and schemas."""
    
    def test_story_model_creation(self):
        """Test Story model creation with valid data."""
        story_data = {
            "id": uuid4(),
            "user_id": uuid4(),
            "title": "Customer Success Story",
            "situation": "Customer had performance issues",
            "task": "Improve system performance",
            "action": "Optimized database queries",
            "result": "50% performance improvement",
            "impact_metrics": {"performance_gain": "50%"},
            "tags": ["performance", "optimization"],
            "status": StoryStatus.COMPLETE.value,
            "ai_enhanced": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        
        story = Story(**story_data)
        
        assert story.title == "Customer Success Story"
        assert story.situation == "Customer had performance issues"
        assert story.status == StoryStatus.COMPLETE.value
        assert story.ai_enhanced is True
    
    def test_story_create_schema_validation(self):
        """Test StoryCreate schema validation."""
        story_data = {
            "title": "Customer Success Story",
            "situation": "Customer had performance issues",
            "task": "Improve system performance",
            "action": "Optimized database queries",
            "result": "50% performance improvement",
            "impact_metrics": {"performance_gain": "50%"},
            "tags": ["performance", "optimization"],
            "status": StoryStatus.COMPLETE
        }
        
        story_create = StoryCreate(**story_data)
        
        assert story_create.title == "Customer Success Story"
        assert story_create.situation == "Customer had performance issues"
        assert story_create.status == StoryStatus.COMPLETE
    
    def test_story_create_schema_empty_star_fields(self):
        """Test StoryCreate schema with empty STAR fields."""
        story_data = {
            "title": "Test Story",
            "situation": "",  # Invalid: should not be empty
            "task": "Test task",
            "action": "Test action",
            "result": "Test result"
        }
        
        with pytest.raises(ValueError):
            StoryCreate(**story_data)


class TestReportModel:
    """Unit tests for Report model and schemas."""
    
    def test_report_model_creation(self):
        """Test Report model creation with valid data."""
        report_data = {
            "id": uuid4(),
            "user_id": uuid4(),
            "title": "Monthly Report",
            "period_start": date(2024, 1, 1),
            "period_end": date(2024, 1, 31),
            "report_type": ReportType.MONTHLY.value,
            "content": "Report content here",
            "activities_included": [uuid4(), uuid4()],
            "stories_included": [uuid4()],
            "generated_by_ai": True,
            "status": ReportStatus.COMPLETE.value,
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        
        report = Report(**report_data)
        
        assert report.title == "Monthly Report"
        assert report.report_type == ReportType.MONTHLY.value
        assert report.generated_by_ai is True
        assert report.status == ReportStatus.COMPLETE.value
    
    def test_report_create_schema_validation(self):
        """Test ReportCreate schema validation."""
        report_data = {
            "title": "Monthly Report",
            "period_start": date(2024, 1, 1),
            "period_end": date(2024, 1, 31),
            "report_type": ReportType.MONTHLY,
            "activities_included": [uuid4(), uuid4()],
            "stories_included": [uuid4()]
        }
        
        report_create = ReportCreate(**report_data)
        
        assert report_create.title == "Monthly Report"
        assert report_create.report_type == ReportType.MONTHLY
        assert len(report_create.activities_included) == 2
        assert len(report_create.stories_included) == 1


class TestModelRelationships:
    """Unit tests for model relationships."""
    
    def test_user_activity_relationship(self):
        """Test User-Activity relationship setup."""
        user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="cognito-123",
            preferences={},
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        activity = Activity(
            id=uuid4(),
            user_id=user.id,
            title="Test Activity",
            description="Test description",
            category=ActivityCategory.LEARNING.value,
            tags=[],
            date=date.today(),
            metadata={},
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        # Verify relationship setup
        assert activity.user_id == user.id
        # Note: In actual database tests, we would verify the relationship works
        # but here we're just testing the model structure
    
    def test_user_story_relationship(self):
        """Test User-Story relationship setup."""
        user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="cognito-123",
            preferences={},
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        story = Story(
            id=uuid4(),
            user_id=user.id,
            title="Test Story",
            situation="Test situation",
            task="Test task",
            action="Test action",
            result="Test result",
            impact_metrics={},
            tags=[],
            status=StoryStatus.DRAFT.value,
            ai_enhanced=False,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        # Verify relationship setup
        assert story.user_id == user.id