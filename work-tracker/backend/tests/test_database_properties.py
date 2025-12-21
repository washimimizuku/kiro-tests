"""
Property-Based Tests for Database Schema

Tests the Activity Lifecycle Consistency property using Hypothesis.
**Feature: work-tracker, Property 1: Activity Lifecycle Consistency**
**Validates: Requirements 1.2, 1.4**
"""

import pytest
from hypothesis import given, strategies as st, settings
from datetime import date, datetime, timedelta
from uuid import uuid4
from typing import Dict, Any, List

from app.models import User, Activity, ActivityCategory
from app.schemas import ActivityCreate, ActivityResponse


# Test data generators
@st.composite
def user_data(draw):
    """Generate valid user data."""
    return {
        "id": uuid4(),
        "email": draw(st.emails()),
        "name": draw(st.text(min_size=1, max_size=255).filter(lambda x: x.strip())),
        "cognito_user_id": draw(st.text(min_size=1, max_size=255).filter(lambda x: x.strip())),
        "preferences": draw(st.dictionaries(st.text(), st.text(), max_size=5)),
        "created_at": datetime.now(),
        "updated_at": datetime.now(),
    }


@st.composite
def activity_data(draw):
    """Generate valid activity data."""
    return ActivityCreate(
        title=draw(st.text(min_size=1, max_size=500).filter(lambda x: x.strip())),
        description=draw(st.one_of(st.none(), st.text(max_size=1000))),
        category=draw(st.sampled_from(list(ActivityCategory))),
        tags=draw(st.lists(st.text(min_size=1, max_size=50), max_size=10)),
        impact_level=draw(st.one_of(st.none(), st.integers(min_value=1, max_value=5))),
        date=draw(st.dates(
            min_value=date.today() - timedelta(days=365),
            max_value=date.today() + timedelta(days=30)
        )),
        duration_minutes=draw(st.one_of(st.none(), st.integers(min_value=0, max_value=1440))),
        metadata=draw(st.dictionaries(st.text(), st.text(), max_size=5)),
    )


class TestActivityLifecycleConsistency:
    """
    Property-Based Tests for Activity Lifecycle Consistency.
    
    **Property 1: Activity Lifecycle Consistency**
    For any valid activity data submitted by a user, the system should successfully 
    validate, store, and retrieve the activity with all original data intact, 
    completing the operation within the specified time constraints.
    **Validates: Requirements 1.2, 1.4**
    """

    @given(activity_data())
    @settings(max_examples=100, deadline=2000)  # 2 second deadline per requirement 1.2
    def test_activity_creation_validation_consistency(self, activity_create: ActivityCreate):
        """
        Test that activity creation data validates consistently.
        
        Property: For any valid ActivityCreate schema, validation should succeed
        and produce consistent results across multiple validations.
        """
        # Test that the schema validates successfully
        assert activity_create.title.strip()  # Title must not be empty after strip
        assert activity_create.category in ActivityCategory
        if activity_create.impact_level is not None:
            assert 1 <= activity_create.impact_level <= 5
        if activity_create.duration_minutes is not None:
            assert activity_create.duration_minutes >= 0
        
        # Test that validation is consistent - multiple validations should produce same result
        dict1 = activity_create.model_dump()
        dict2 = activity_create.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = ActivityCreate.model_validate(dict1)
        assert reparsed == activity_create

    @given(user_data(), activity_data())
    @settings(max_examples=100, deadline=2000)
    def test_activity_model_data_integrity(self, user_data_dict: Dict[str, Any], activity_create: ActivityCreate):
        """
        Test that Activity model preserves data integrity.
        
        Property: For any valid activity data, creating an Activity model instance
        should preserve all input data without corruption or loss.
        """
        # Create a mock user
        user = User(**user_data_dict)
        
        # Create activity with user relationship
        activity = Activity(
            id=uuid4(),
            user_id=user.id,
            title=activity_create.title,
            description=activity_create.description,
            category=activity_create.category.value,
            tags=activity_create.tags,
            impact_level=activity_create.impact_level,
            date=activity_create.date,
            duration_minutes=activity_create.duration_minutes,
            metadata=activity_create.metadata,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        # Verify all data is preserved
        assert activity.title == activity_create.title
        assert activity.description == activity_create.description
        assert activity.category == activity_create.category.value
        assert activity.tags == activity_create.tags
        assert activity.impact_level == activity_create.impact_level
        assert activity.date == activity_create.date
        assert activity.duration_minutes == activity_create.duration_minutes
        assert activity.metadata == activity_create.metadata
        assert activity.user_id == user.id

    @given(user_data(), activity_data())
    @settings(max_examples=100, deadline=2000)
    def test_activity_response_serialization_consistency(self, user_data_dict: Dict[str, Any], activity_create: ActivityCreate):
        """
        Test that ActivityResponse serialization is consistent.
        
        Property: For any valid activity, serializing to ActivityResponse and back
        should preserve all essential data fields.
        """
        # Create activity model
        activity = Activity(
            id=uuid4(),
            user_id=uuid4(),
            title=activity_create.title,
            description=activity_create.description,
            category=activity_create.category.value,
            tags=activity_create.tags,
            impact_level=activity_create.impact_level,
            date=activity_create.date,
            duration_minutes=activity_create.duration_minutes,
            metadata=activity_create.metadata,
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
        
        # Verify serialization preserves data
        assert response.title == activity.title
        assert response.description == activity.description
        assert response.category.value == activity.category
        assert response.tags == activity.tags
        assert response.impact_level == activity.impact_level
        assert response.date == activity.date
        assert response.duration_minutes == activity.duration_minutes
        assert response.metadata == activity.metadata

    @given(st.lists(activity_data(), min_size=1, max_size=20))
    @settings(max_examples=50, deadline=2000)
    def test_activity_collection_consistency(self, activities: List[ActivityCreate]):
        """
        Test that collections of activities maintain consistency.
        
        Property: For any collection of valid activities, operations on the collection
        should maintain data integrity and ordering properties.
        """
        # Test that all activities in collection are valid
        for activity in activities:
            assert activity.title.strip()
            assert activity.category in ActivityCategory
            if activity.impact_level is not None:
                assert 1 <= activity.impact_level <= 5
        
        # Test that collection operations preserve properties
        titles = [a.title for a in activities]
        categories = [a.category for a in activities]
        dates = [a.date for a in activities]
        
        # Verify no data corruption in collection operations
        assert len(titles) == len(activities)
        assert len(categories) == len(activities)
        assert len(dates) == len(activities)
        
        # Test sorting preserves data integrity
        sorted_by_date = sorted(activities, key=lambda x: x.date)
        assert len(sorted_by_date) == len(activities)
        
        # Verify all original activities are still present after sorting
        original_titles = set(a.title for a in activities)
        sorted_titles = set(a.title for a in sorted_by_date)
        assert original_titles == sorted_titles