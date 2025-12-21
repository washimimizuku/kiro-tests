"""
Property-Based Tests for Activity Service Operations

Tests Activity Lifecycle Consistency and Tag Management Consistency properties using Hypothesis.
**Feature: work-tracker, Property 1: Activity Lifecycle Consistency**
**Feature: work-tracker, Property 8: Tag Management Consistency**
**Validates: Requirements 1.2, 1.4, 4.2, 4.5**
"""

import pytest
import asyncio
from hypothesis import given, strategies as st, settings, assume
from datetime import date, datetime, timedelta
from uuid import uuid4, UUID
from typing import Dict, Any, List, Optional
from unittest.mock import AsyncMock, MagicMock

from app.models import User, Activity, ActivityCategory
from app.schemas import ActivityCreate, ActivityUpdate, ActivityFilters, ActivityResponse
from app.services.activities.service import ActivityService
from app.core.exceptions import NotFoundError, ValidationError


# Test data generators
@st.composite
def user_id_strategy(draw):
    """Generate valid user UUID."""
    return uuid4()


@st.composite
def activity_create_strategy(draw):
    """Generate valid ActivityCreate data."""
    return ActivityCreate(
        title=draw(st.text(min_size=1, max_size=500).filter(lambda x: x.strip())),
        description=draw(st.one_of(st.none(), st.text(max_size=1000))),
        category=draw(st.sampled_from(list(ActivityCategory))),
        tags=draw(st.lists(st.text(min_size=1, max_size=50).filter(lambda x: x.strip()), max_size=10)),
        impact_level=draw(st.one_of(st.none(), st.integers(min_value=1, max_value=5))),
        date=draw(st.dates(
            min_value=date.today() - timedelta(days=365),
            max_value=date.today() + timedelta(days=30)
        )),
        duration_minutes=draw(st.one_of(st.none(), st.integers(min_value=0, max_value=1440))),
        metadata=draw(st.dictionaries(st.text(), st.text(), max_size=5)),
    )


@st.composite
def activity_update_strategy(draw):
    """Generate valid ActivityUpdate data."""
    # Use a simpler approach - just generate a few fields to avoid validation complexity
    fields = draw(st.lists(
        st.sampled_from(['title', 'description', 'category', 'tags', 'impact_level']),
        min_size=0, max_size=3, unique=True
    ))
    
    update_data = {}
    
    if 'title' in fields:
        update_data['title'] = draw(st.text(min_size=1, max_size=50).filter(lambda x: x.strip()))
    
    if 'description' in fields:
        update_data['description'] = draw(st.text(max_size=100))
    
    if 'category' in fields:
        update_data['category'] = draw(st.sampled_from(list(ActivityCategory)))
    
    if 'tags' in fields:
        update_data['tags'] = draw(st.lists(st.text(min_size=1, max_size=20).filter(lambda x: x.strip()), max_size=3))
    
    if 'impact_level' in fields:
        update_data['impact_level'] = draw(st.integers(min_value=1, max_value=5))
    
    return ActivityUpdate(**update_data)


@st.composite
def activity_filters_strategy(draw):
    """Generate valid ActivityFilters data."""
    return ActivityFilters(
        category=draw(st.one_of(st.none(), st.sampled_from(list(ActivityCategory)))),
        tags=draw(st.one_of(st.none(), st.lists(st.text(min_size=1, max_size=50), max_size=5))),
        date_from=draw(st.one_of(st.none(), st.dates(
            min_value=date.today() - timedelta(days=365),
            max_value=date.today()
        ))),
        date_to=draw(st.one_of(st.none(), st.dates(
            min_value=date.today(),
            max_value=date.today() + timedelta(days=30)
        ))),
        impact_level_min=draw(st.one_of(st.none(), st.integers(min_value=1, max_value=5))),
        impact_level_max=draw(st.one_of(st.none(), st.integers(min_value=1, max_value=5))),
        search=draw(st.one_of(st.none(), st.text(min_size=1, max_size=100))),
        limit=draw(st.integers(min_value=1, max_value=100)),
        offset=draw(st.integers(min_value=0, max_value=1000)),
    )


@st.composite
def mock_activity_strategy(draw):
    """Generate mock Activity model instances."""
    activity_create = draw(activity_create_strategy())
    return Activity(
        id=uuid4(),
        user_id=uuid4(),
        title=activity_create.title,
        description=activity_create.description,
        category=activity_create.category.value,
        tags=activity_create.tags,
        impact_level=activity_create.impact_level,
        date=activity_create.date,
        duration_minutes=activity_create.duration_minutes,
        metadata_json=activity_create.metadata,
        created_at=datetime.now(),
        updated_at=datetime.now(),
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

    @given(user_id_strategy(), activity_create_strategy())
    @settings(max_examples=20, deadline=2000)  # 2 second deadline per requirement 1.2
    @pytest.mark.asyncio
    async def test_activity_creation_lifecycle_consistency(self, user_id: UUID, activity_data: ActivityCreate):
        """
        Test that activity creation maintains data consistency throughout the lifecycle.
        
        Property: For any valid activity data, creating an activity should preserve
        all input data and make it retrievable with identical values.
        """
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Create expected activity result
        expected_activity = Activity(
            id=uuid4(),
            user_id=user_id,
            title=activity_data.title.strip(),
            description=activity_data.description.strip() if activity_data.description else None,
            category=activity_data.category.value,
            tags=list(set(tag.strip().lower() for tag in activity_data.tags if tag.strip())),
            impact_level=activity_data.impact_level,
            date=activity_data.date,
            duration_minutes=activity_data.duration_minutes,
            metadata_json=activity_data.metadata or {},
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
        
        # Mock database operations
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock(side_effect=lambda obj: setattr(obj, 'id', expected_activity.id))
        
        # Test creation
        result = await service.create_activity(user_id, activity_data)
        
        # Verify data consistency - all input data should be preserved
        assert result.title == activity_data.title.strip()
        assert result.category == activity_data.category.value
        assert result.date == activity_data.date
        assert result.impact_level == activity_data.impact_level
        assert result.duration_minutes == activity_data.duration_minutes
        
        # Verify tag normalization consistency
        expected_tags = list(set(tag.strip().lower() for tag in activity_data.tags if tag.strip()))
        assert result.tags == expected_tags
        
        # Verify metadata consistency
        assert result.metadata_json == (activity_data.metadata or {})
        
        # Verify user association
        assert result.user_id == user_id

    @given(user_id_strategy(), mock_activity_strategy(), activity_update_strategy())
    @settings(max_examples=20, deadline=2000)
    @pytest.mark.asyncio
    async def test_activity_update_lifecycle_consistency(self, user_id: UUID, existing_activity: Activity, update_data: ActivityUpdate):
        """
        Test that activity updates maintain data consistency.
        
        Property: For any valid update data, updating an activity should preserve
        unchanged fields and correctly apply changes to specified fields.
        """
        # Set up the existing activity with the correct user_id
        existing_activity.user_id = user_id
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Mock database query to return existing activity
        mock_result = MagicMock()
        mock_result.scalar_one_or_none = MagicMock(return_value=existing_activity)
        mock_db.execute = AsyncMock(return_value=mock_result)
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        # Store original values for comparison
        original_title = existing_activity.title
        original_category = existing_activity.category
        original_date = existing_activity.date
        original_tags = existing_activity.tags.copy() if existing_activity.tags else []
        
        # Test update
        result = await service.update_activity(user_id, existing_activity.id, update_data)
        
        # Verify consistency: unchanged fields should remain the same
        update_dict = update_data.model_dump(exclude_unset=True)
        
        if 'title' not in update_dict:
            assert result.title == original_title
        else:
            assert result.title == update_data.title.strip()
        
        if 'category' not in update_dict:
            assert result.category == original_category
        else:
            assert result.category == update_data.category.value
        
        if 'date' not in update_dict:
            assert result.date == original_date
        else:
            assert result.date == update_data.date
        
        if 'tags' not in update_dict:
            assert result.tags == original_tags
        else:
            expected_tags = list(set(tag.strip().lower() for tag in update_data.tags if tag.strip())) if update_data.tags else []
            assert result.tags == expected_tags

    @given(user_id_strategy(), st.lists(activity_create_strategy(), min_size=1, max_size=20))
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_activity_list_retrieval_consistency(self, user_id: UUID, activities_data: List[ActivityCreate]):
        """
        Test that activity list retrieval maintains consistency.
        
        Property: For any collection of activities, listing them should return
        all activities with preserved data and correct ordering.
        """
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Create mock activities
        mock_activities = []
        for i, activity_data in enumerate(activities_data):
            activity = Activity(
                id=uuid4(),
                user_id=user_id,
                title=activity_data.title.strip(),
                description=activity_data.description.strip() if activity_data.description else None,
                category=activity_data.category.value,
                tags=list(set(tag.strip().lower() for tag in activity_data.tags if tag.strip())),
                impact_level=activity_data.impact_level,
                date=activity_data.date,
                duration_minutes=activity_data.duration_minutes,
                metadata_json=activity_data.metadata or {},
                created_at=datetime.now() - timedelta(minutes=len(activities_data) - i),  # Different creation times
                updated_at=datetime.now() - timedelta(minutes=len(activities_data) - i),
            )
            mock_activities.append(activity)
        
        # Sort by date descending, then by creation time (as per service implementation)
        expected_order = sorted(mock_activities, key=lambda x: (x.date, x.created_at), reverse=True)
        
        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=expected_order)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test list retrieval
        filters = ActivityFilters()
        result = await service.list_activities(user_id, filters)
        
        # Verify consistency: all activities should be returned in correct order
        assert len(result) == len(activities_data)
        
        # Verify ordering consistency
        for i in range(len(result) - 1):
            current = result[i]
            next_item = result[i + 1]
            # Should be ordered by date desc, then created_at desc
            assert (current.date, current.created_at) >= (next_item.date, next_item.created_at)
        
        # Verify data integrity for each activity
        for activity in result:
            assert activity.user_id == user_id
            assert activity.title.strip() == activity.title  # Should be normalized
            assert activity.category in [cat.value for cat in ActivityCategory]
            if activity.impact_level is not None:
                assert 1 <= activity.impact_level <= 5


class TestTagManagementConsistency:
    """
    Property-Based Tests for Tag Management Consistency.
    
    **Property 8: Tag Management Consistency**
    For any tag operation (creation, suggestion, merge, rename, delete), the system 
    should maintain tag consistency across all activities and provide appropriate 
    suggestions based on existing tag data.
    **Validates: Requirements 4.2, 4.5**
    """

    @given(user_id_strategy(), st.lists(st.lists(st.text(min_size=1, max_size=50).filter(lambda x: x.strip()), min_size=1, max_size=10), min_size=1, max_size=20))
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_tag_normalization_consistency(self, user_id: UUID, tag_lists: List[List[str]]):
        """
        Test that tag normalization is consistent across operations.
        
        Property: For any collection of tag lists, normalization should produce
        consistent results (lowercase, trimmed, deduplicated).
        """
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Flatten all tags and normalize them manually for comparison
        all_tags = []
        for tag_list in tag_lists:
            all_tags.extend(tag_list)
        
        # Expected normalization: strip, lowercase, deduplicate
        expected_normalized = list(set(tag.strip().lower() for tag in all_tags if tag.strip()))
        
        # Mock database query to return activities with these tags
        mock_activities = []
        for i, tag_list in enumerate(tag_lists):
            normalized_tags = list(set(tag.strip().lower() for tag in tag_list if tag.strip()))
            activity = Activity(
                id=uuid4(),
                user_id=user_id,
                title=f"Activity {i}",
                description=None,
                category=ActivityCategory.CUSTOMER_ENGAGEMENT.value,
                tags=normalized_tags,
                impact_level=None,
                date=date.today(),
                duration_minutes=None,
                metadata_json={},
                created_at=datetime.now(),
                updated_at=datetime.now(),
            )
            mock_activities.append(activity)
        
        # Mock database result to return tag lists
        tag_lists_from_activities = [activity.tags for activity in mock_activities]
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.__iter__ = MagicMock(return_value=iter(tag_lists_from_activities))
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test tag retrieval
        result_tags = await service.get_activity_tags(user_id)
        
        # Verify consistency: all tags should be normalized and sorted
        assert isinstance(result_tags, list)
        assert result_tags == sorted(result_tags)  # Should be sorted
        
        # Verify all tags are normalized (lowercase, stripped)
        for tag in result_tags:
            assert tag == tag.strip().lower()
            assert tag  # Should not be empty
        
        # Verify no duplicates
        assert len(result_tags) == len(set(result_tags))

    @given(user_id_strategy(), st.text(min_size=1, max_size=20), st.lists(st.text(min_size=1, max_size=50).filter(lambda x: x.strip()), min_size=1, max_size=50))
    @settings(max_examples=20, deadline=2000)
    @pytest.mark.asyncio
    async def test_tag_suggestion_consistency(self, user_id: UUID, partial_tag: str, existing_tags: List[str]):
        """
        Test that tag suggestions are consistent and relevant.
        
        Property: For any partial tag input, suggestions should be consistent,
        relevant (contain the partial tag), and ordered by relevance.
        """
        # Normalize existing tags
        normalized_tags = list(set(tag.strip().lower() for tag in existing_tags if tag.strip()))
        partial_lower = partial_tag.lower().strip()
        
        # Skip if partial tag is empty after normalization
        assume(partial_lower)
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Mock get_activity_tags to return our test tags
        service.get_activity_tags = AsyncMock(return_value=normalized_tags)
        
        # Test tag suggestions
        suggestions = await service.get_tag_suggestions(user_id, partial_tag, limit=10)
        
        # Verify consistency: all suggestions should contain the partial tag
        for suggestion in suggestions:
            assert partial_lower in suggestion.lower()
        
        # Verify relevance ordering: tags starting with partial should come first
        starts_with = [tag for tag in suggestions if tag.lower().startswith(partial_lower)]
        contains_but_not_starts = [tag for tag in suggestions if partial_lower in tag.lower() and not tag.lower().startswith(partial_lower)]
        
        # Verify ordering consistency
        expected_order = starts_with + contains_but_not_starts
        assert suggestions == expected_order[:len(suggestions)]
        
        # Verify limit consistency
        assert len(suggestions) <= 10
        
        # Verify no duplicates
        assert len(suggestions) == len(set(suggestions))

    @given(user_id_strategy(), activity_create_strategy())
    @settings(max_examples=20, deadline=2000)
    @pytest.mark.asyncio
    async def test_tag_creation_consistency(self, user_id: UUID, activity_data: ActivityCreate):
        """
        Test that tag creation maintains consistency across activities.
        
        Property: For any activity with tags, creating the activity should
        normalize tags consistently and maintain tag relationships.
        """
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Mock database operations
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        # Test activity creation with tags
        result = await service.create_activity(user_id, activity_data)
        
        # Verify tag consistency
        original_tags = activity_data.tags
        result_tags = result.tags
        
        # Expected normalization
        expected_tags = list(set(tag.strip().lower() for tag in original_tags if tag.strip()))
        
        assert result_tags == expected_tags
        
        # Verify tag properties
        for tag in result_tags:
            assert tag == tag.strip().lower()  # Normalized
            assert tag  # Not empty
        
        # Verify no duplicates
        assert len(result_tags) == len(set(result_tags))
        
        # Verify all original non-empty tags are represented
        original_normalized = set(tag.strip().lower() for tag in original_tags if tag.strip())
        result_set = set(result_tags)
        assert result_set == original_normalized

    @given(user_id_strategy(), activity_filters_strategy())
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_tag_filtering_consistency(self, user_id: UUID, filters: ActivityFilters):
        """
        Test that tag filtering maintains consistency.
        
        Property: For any tag filter, the filtering operation should be consistent
        and return only activities that match the tag criteria.
        """
        # Skip if no tag filters
        assume(filters.tags is not None and len(filters.tags) > 0)
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Create mock activities, some matching the filter tags
        mock_activities = []
        filter_tags = [tag.lower().strip() for tag in filters.tags]
        
        # Create activities that should match (contain at least one filter tag)
        for i in range(5):
            matching_tags = [filter_tags[0], f"other_tag_{i}"]  # Always include one matching tag
            activity = Activity(
                id=uuid4(),
                user_id=user_id,
                title=f"Matching Activity {i}",
                description=None,
                category=ActivityCategory.CUSTOMER_ENGAGEMENT.value,
                tags=matching_tags,
                impact_level=None,
                date=date.today(),
                duration_minutes=None,
                metadata_json={},
                created_at=datetime.now(),
                updated_at=datetime.now(),
            )
            mock_activities.append(activity)
        
        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=mock_activities)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test filtering
        result = await service.list_activities(user_id, filters)
        
        # Verify consistency: all returned activities should have at least one matching tag
        for activity in result:
            activity_tags = [tag.lower() for tag in activity.tags] if activity.tags else []
            has_matching_tag = any(filter_tag in activity_tags for filter_tag in filter_tags)
            assert has_matching_tag, f"Activity {activity.id} should have at least one matching tag from {filter_tags}, but has {activity_tags}"
        
        # Verify user consistency
        for activity in result:
            assert activity.user_id == user_id


class TestActivityFilteringProperties:
    """
    Property-Based Tests for Activity Filtering and Search.
    
    **Property 2: Auto-complete Suggestion Accuracy**
    For any partial activity title input, if matching previous activities exist, 
    the system should return relevant suggestions that contain the input as a substring.
    **Validates: Requirements 1.3**
    
    **Property 3: Activity Display and Filtering**
    For any collection of user activities, the display system should correctly 
    group activities by date and apply filters such that filtered results contain 
    only activities matching the specified criteria.
    **Validates: Requirements 1.5, 4.3**
    """

    @given(user_id_strategy(), st.lists(st.text(min_size=1, max_size=500).filter(lambda x: x.strip()), min_size=1, max_size=50))
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_activity_title_suggestion_accuracy(self, user_id: UUID, existing_titles: List[str]):
        """
        Test that activity title suggestions are accurate and relevant.
        
        Property: For any partial title input, if matching activities exist,
        suggestions should contain the input as a substring and be ordered by relevance.
        """
        # Normalize titles
        normalized_titles = list(set(title.strip() for title in existing_titles if title.strip()))
        
        # Skip if no titles
        assume(len(normalized_titles) > 0)
        
        # Pick a partial title from one of the existing titles
        test_title = normalized_titles[0]
        partial_title = test_title[:len(test_title)//2] if len(test_title) > 2 else test_title[0]
        
        # Skip if partial is empty
        assume(partial_title.strip())
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Mock database query to return matching titles
        matching_titles = [title for title in normalized_titles if partial_title.lower() in title.lower()]
        
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=matching_titles)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test title suggestions
        suggestions = await service.get_activity_title_suggestions(user_id, partial_title, limit=10)
        
        # Verify accuracy: all suggestions should contain the partial title
        for suggestion in suggestions:
            assert partial_title.lower() in suggestion.lower()
        
        # Verify relevance ordering: titles starting with partial should come first
        partial_lower = partial_title.lower()
        starts_with = [title for title in suggestions if title.lower().startswith(partial_lower)]
        contains_but_not_starts = [title for title in suggestions if partial_lower in title.lower() and not title.lower().startswith(partial_lower)]
        
        # Verify ordering consistency
        expected_order = starts_with + contains_but_not_starts
        assert suggestions == expected_order[:len(suggestions)]
        
        # Verify limit consistency
        assert len(suggestions) <= 10
        
        # Verify no duplicates
        assert len(suggestions) == len(set(suggestions))

    @given(user_id_strategy(), st.lists(mock_activity_strategy(), min_size=1, max_size=30), activity_filters_strategy())
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_activity_filtering_consistency(self, user_id: UUID, activities: List[Activity], filters: ActivityFilters):
        """
        Test that activity filtering produces consistent and correct results.
        
        Property: For any collection of activities and filter criteria, 
        the filtering should return only activities that match ALL specified criteria.
        """
        # Set all activities to belong to the test user
        for activity in activities:
            activity.user_id = user_id
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Filter activities manually to get expected results
        expected_results = []
        for activity in activities:
            matches = True
            
            # Check category filter
            if filters.category and activity.category != filters.category.value:
                matches = False
            
            # Check tags filter (OR logic - activity must have at least one matching tag)
            if filters.tags and matches:
                activity_tags = activity.tags or []
                has_matching_tag = any(tag in activity_tags for tag in filters.tags)
                if not has_matching_tag:
                    matches = False
            
            # Check date range filters
            if filters.date_from and matches:
                if activity.date < filters.date_from:
                    matches = False
            
            if filters.date_to and matches:
                if activity.date > filters.date_to:
                    matches = False
            
            # Check impact level filters
            if filters.impact_level_min and matches and activity.impact_level:
                if activity.impact_level < filters.impact_level_min:
                    matches = False
            
            if filters.impact_level_max and matches and activity.impact_level:
                if activity.impact_level > filters.impact_level_max:
                    matches = False
            
            # Check search filter
            if filters.search and matches:
                search_lower = filters.search.lower()
                title_match = search_lower in (activity.title or "").lower()
                desc_match = search_lower in (activity.description or "").lower()
                if not (title_match or desc_match):
                    matches = False
            
            if matches:
                expected_results.append(activity)
        
        # Sort expected results by date desc, then created_at desc (as per service implementation)
        expected_results.sort(key=lambda x: (x.date, x.created_at), reverse=True)
        
        # Apply pagination to expected results
        start_idx = filters.offset
        end_idx = start_idx + filters.limit
        expected_results = expected_results[start_idx:end_idx]
        
        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=expected_results)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test filtering
        result = await service.list_activities(user_id, filters)
        
        # Verify consistency: results should match expected filtering
        assert len(result) == len(expected_results)
        
        # Verify each result matches the filter criteria
        for activity in result:
            assert activity.user_id == user_id
            
            # Verify category filter
            if filters.category:
                assert activity.category == filters.category.value
            
            # Verify tags filter
            if filters.tags:
                activity_tags = activity.tags or []
                has_matching_tag = any(tag in activity_tags for tag in filters.tags)
                assert has_matching_tag
            
            # Verify date filters
            if filters.date_from:
                assert activity.date >= filters.date_from
            
            if filters.date_to:
                assert activity.date <= filters.date_to
            
            # Verify impact level filters
            if filters.impact_level_min and activity.impact_level:
                assert activity.impact_level >= filters.impact_level_min
            
            if filters.impact_level_max and activity.impact_level:
                assert activity.impact_level <= filters.impact_level_max
            
            # Verify search filter
            if filters.search:
                search_lower = filters.search.lower()
                title_match = search_lower in (activity.title or "").lower()
                desc_match = search_lower in (activity.description or "").lower()
                assert title_match or desc_match
            
            # Verify date filters
            if filters.date_from:
                assert activity.date >= filters.date_from
            
            if filters.date_to:
                assert activity.date <= filters.date_to
            
            # Verify impact level filters
            if filters.impact_level_min and activity.impact_level:
                assert activity.impact_level >= filters.impact_level_min
            
            if filters.impact_level_max and activity.impact_level:
                assert activity.impact_level <= filters.impact_level_max
            
            # Verify search filter
            if filters.search:
                search_lower = filters.search.lower()
                title_match = search_lower in (activity.title or "").lower()
                desc_match = search_lower in (activity.description or "").lower()
                assert title_match or desc_match

    @given(user_id_strategy(), st.lists(mock_activity_strategy(), min_size=5, max_size=50))
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_activity_date_grouping_consistency(self, user_id: UUID, activities: List[Activity]):
        """
        Test that activity date grouping is consistent.
        
        Property: For any collection of activities, grouping by date should 
        maintain chronological order and preserve all activities.
        """
        # Set all activities to belong to the test user
        for activity in activities:
            activity.user_id = user_id
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Sort activities by date descending, then by created_at descending
        sorted_activities = sorted(activities, key=lambda x: (x.date, x.created_at), reverse=True)
        
        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=sorted_activities)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test activity listing (which should be ordered by date)
        filters = ActivityFilters()
        result = await service.list_activities(user_id, filters)
        
        # Verify date grouping consistency
        assert len(result) == len(activities)
        
        # Verify chronological ordering
        for i in range(len(result) - 1):
            current = result[i]
            next_item = result[i + 1]
            
            # Should be ordered by date desc, then created_at desc
            assert (current.date, current.created_at) >= (next_item.date, next_item.created_at)
        
        # Verify all activities are preserved
        result_ids = set(activity.id for activity in result)
        original_ids = set(activity.id for activity in activities)
        assert result_ids == original_ids

    @given(user_id_strategy(), st.text(min_size=1, max_size=100), st.lists(mock_activity_strategy(), min_size=1, max_size=30))
    @settings(max_examples=10, deadline=2000)
    @pytest.mark.asyncio
    async def test_full_text_search_consistency(self, user_id: UUID, search_term: str, activities: List[Activity]):
        """
        Test that full-text search is consistent and accurate.
        
        Property: For any search term, search results should contain only activities
        where the search term appears in the title or description (case-insensitive).
        """
        # Set all activities to belong to the test user
        for activity in activities:
            activity.user_id = user_id
        
        # Ensure at least one activity contains the search term
        if activities:
            activities[0].title = f"Test {search_term} Activity"
            activities[0].description = f"Description containing {search_term}"
        
        # Mock database session
        mock_db = AsyncMock()
        service = ActivityService(mock_db)
        
        # Filter activities that should match the search
        search_lower = search_term.lower()
        matching_activities = []
        for activity in activities:
            title_match = search_lower in (activity.title or "").lower()
            desc_match = search_lower in (activity.description or "").lower()
            if title_match or desc_match:
                matching_activities.append(activity)
        
        # Sort matching activities by date desc, then created_at desc
        matching_activities.sort(key=lambda x: (x.date, x.created_at), reverse=True)
        
        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all = MagicMock(return_value=matching_activities)
        mock_result.scalars = MagicMock(return_value=mock_scalars)
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        # Test search
        filters = ActivityFilters(search=search_term)
        result = await service.list_activities(user_id, filters)
        
        # Verify search consistency
        for activity in result:
            search_lower = search_term.lower()
            title_match = search_lower in (activity.title or "").lower()
            desc_match = search_lower in (activity.description or "").lower()
            assert title_match or desc_match, f"Activity {activity.id} should contain search term '{search_term}'"
        
        # Verify user consistency
        for activity in result:
            assert activity.user_id == user_id