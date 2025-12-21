#!/usr/bin/env python3
"""
Simple test runner for property-based tests.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from hypothesis import given, strategies as st, settings
from datetime import date, datetime, timedelta
from uuid import uuid4

from app.models.activity import ActivityCategory
from app.schemas.activity import ActivityCreate


# Test data generators
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


@given(activity_data())
@settings(max_examples=100, deadline=2000)
def test_activity_creation_validation_consistency(activity_create: ActivityCreate):
    """
    **Feature: work-tracker, Property 1: Activity Lifecycle Consistency**
    **Validates: Requirements 1.2, 1.4**
    
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


if __name__ == "__main__":
    print("Running Property-Based Test for Activity Lifecycle Consistency...")
    print("**Feature: work-tracker, Property 1: Activity Lifecycle Consistency**")
    print("**Validates: Requirements 1.2, 1.4**")
    
    try:
        test_activity_creation_validation_consistency()
        print("✅ Property test PASSED: Activity creation validation consistency")
    except Exception as e:
        print(f"❌ Property test FAILED: {e}")
        sys.exit(1)
    
    print("All property tests completed successfully!")