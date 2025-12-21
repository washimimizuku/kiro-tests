#!/usr/bin/env python3
"""
Simple test runner for unit tests.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from datetime import date, datetime
from uuid import uuid4

from app.models import User, Activity, ActivityCategory, Story, StoryStatus, Report, ReportType, ReportStatus
from app.schemas import (
    UserCreate, UserResponse, ActivityCreate, ActivityResponse, 
    StoryCreate, StoryResponse, ReportCreate, ReportResponse
)


def test_user_model_creation():
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
    print("✅ User model creation test passed")


def test_user_create_schema_validation():
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
    print("✅ UserCreate schema validation test passed")


def test_activity_model_creation():
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
    print("✅ Activity model creation test passed")


def test_activity_create_schema_validation():
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
    print("✅ ActivityCreate schema validation test passed")


def test_story_model_creation():
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
    print("✅ Story model creation test passed")


def test_story_create_schema_validation():
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
    print("✅ StoryCreate schema validation test passed")


def test_report_model_creation():
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
    print("✅ Report model creation test passed")


def test_activity_serialization_deserialization():
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
    print("✅ Activity serialization/deserialization test passed")


if __name__ == "__main__":
    print("Running Unit Tests for Data Models...")
    print("Testing model validation and relationships")
    print("Testing schema serialization/deserialization")
    print()
    
    try:
        test_user_model_creation()
        test_user_create_schema_validation()
        test_activity_model_creation()
        test_activity_create_schema_validation()
        test_story_model_creation()
        test_story_create_schema_validation()
        test_report_model_creation()
        test_activity_serialization_deserialization()
        
        print()
        print("🎉 All unit tests passed successfully!")
        print("✅ Model validation tests completed")
        print("✅ Schema serialization/deserialization tests completed")
        print("✅ Requirements 1.2, 2.3 validated")
        
    except Exception as e:
        print(f"❌ Unit test failed: {e}")
        sys.exit(1)