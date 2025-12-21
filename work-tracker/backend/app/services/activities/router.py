"""
Activity Router

FastAPI router for activity management endpoints.
Provides CRUD operations, filtering, search, and tag management.
"""

from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.services.auth.jwt_middleware import get_current_user
from app.services.activities.service import ActivityService
from app.schemas.activity import (
    ActivityCreate, 
    ActivityUpdate, 
    ActivityResponse, 
    ActivityFilters,
    ActivitySummary
)
from app.schemas.user import UserResponse
from app.core.exceptions import NotFoundError, ValidationError

router = APIRouter()


def get_activity_service(db: AsyncSession = Depends(get_db)) -> ActivityService:
    """Dependency to get activity service instance."""
    return ActivityService(db)


@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    activity_data: ActivityCreate,
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Create a new activity for the current user.
    
    - **title**: Activity title (required, max 500 chars)
    - **description**: Optional detailed description
    - **category**: Activity category (required)
    - **tags**: List of tags for categorization
    - **impact_level**: Impact level from 1-5 (optional)
    - **date**: Date of the activity (required)
    - **duration_minutes**: Duration in minutes (optional)
    - **metadata**: Additional metadata as JSON (optional)
    """
    try:
        activity = await activity_service.create_activity(current_user.id, activity_data)
        return ActivityResponse.model_validate(activity)
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(
    activity_id: UUID,
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Get a specific activity by ID.
    
    Returns the activity details if it belongs to the current user.
    """
    try:
        activity = await activity_service.get_activity(current_user.id, activity_id)
        return ActivityResponse.model_validate(activity)
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )


@router.get("/", response_model=List[ActivityResponse])
async def list_activities(
    category: str = Query(None, description="Filter by activity category"),
    tags: List[str] = Query(None, description="Filter by tags (OR logic)"),
    date_from: str = Query(None, description="Filter activities from this date (YYYY-MM-DD)"),
    date_to: str = Query(None, description="Filter activities to this date (YYYY-MM-DD)"),
    impact_level_min: int = Query(None, ge=1, le=5, description="Minimum impact level"),
    impact_level_max: int = Query(None, ge=1, le=5, description="Maximum impact level"),
    search: str = Query(None, description="Search in title and description"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    List activities for the current user with optional filtering.
    
    Supports filtering by:
    - **category**: Activity category
    - **tags**: List of tags (OR logic - activity must have at least one)
    - **date_from/date_to**: Date range filtering
    - **impact_level_min/max**: Impact level range
    - **search**: Text search in title and description
    - **limit/offset**: Pagination
    
    Results are ordered by date (newest first), then by creation time.
    """
    try:
        # Parse date strings if provided
        from datetime import datetime
        parsed_date_from = None
        parsed_date_to = None
        
        if date_from:
            try:
                parsed_date_from = datetime.strptime(date_from, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date_from format. Use YYYY-MM-DD"
                )
        
        if date_to:
            try:
                parsed_date_to = datetime.strptime(date_to, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date_to format. Use YYYY-MM-DD"
                )
        
        # Parse category if provided
        from app.models.activity import ActivityCategory
        parsed_category = None
        if category:
            try:
                parsed_category = ActivityCategory(category)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category. Must be one of: {[c.value for c in ActivityCategory]}"
                )
        
        filters = ActivityFilters(
            category=parsed_category,
            tags=tags,
            date_from=parsed_date_from,
            date_to=parsed_date_to,
            impact_level_min=impact_level_min,
            impact_level_max=impact_level_max,
            search=search,
            limit=limit,
            offset=offset
        )
        
        activities = await activity_service.list_activities(current_user.id, filters)
        return [ActivityResponse.model_validate(activity) for activity in activities]
    
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put("/{activity_id}", response_model=ActivityResponse)
async def update_activity(
    activity_id: UUID,
    update_data: ActivityUpdate,
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Update an existing activity.
    
    Only provided fields will be updated. All fields are optional.
    """
    try:
        activity = await activity_service.update_activity(current_user.id, activity_id, update_data)
        return ActivityResponse.model_validate(activity)
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: UUID,
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Delete an activity.
    
    Permanently removes the activity from the system.
    """
    try:
        await activity_service.delete_activity(current_user.id, activity_id)
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )


@router.get("/tags/all", response_model=List[str])
async def get_user_tags(
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Get all unique tags used by the current user.
    
    Returns a sorted list of all tags that have been used in the user's activities.
    """
    tags = await activity_service.get_activity_tags(current_user.id)
    return tags


@router.get("/titles/suggestions", response_model=List[str])
async def get_activity_title_suggestions(
    q: str = Query(..., min_length=1, description="Partial title to search for"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of suggestions"),
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Get activity title suggestions based on partial input.
    
    Returns activity titles that start with or contain the query string, ordered by relevance.
    Useful for auto-complete functionality in the frontend.
    """
    suggestions = await activity_service.get_activity_title_suggestions(current_user.id, q, limit)
    return suggestions


@router.get("/tags/suggestions", response_model=List[str])
async def get_tag_suggestions(
    q: str = Query(..., min_length=1, description="Partial tag to search for"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of suggestions"),
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Get tag suggestions based on partial input.
    
    Returns tags that start with or contain the query string, ordered by relevance.
    """
    suggestions = await activity_service.get_tag_suggestions(current_user.id, q, limit)
    return suggestions


@router.get("/count", response_model=int)
async def get_activity_count(
    category: str = Query(None, description="Filter by activity category"),
    tags: List[str] = Query(None, description="Filter by tags (OR logic)"),
    date_from: str = Query(None, description="Filter activities from this date (YYYY-MM-DD)"),
    date_to: str = Query(None, description="Filter activities to this date (YYYY-MM-DD)"),
    impact_level_min: int = Query(None, ge=1, le=5, description="Minimum impact level"),
    impact_level_max: int = Query(None, ge=1, le=5, description="Maximum impact level"),
    search: str = Query(None, description="Search in title and description"),
    current_user: UserResponse = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service)
):
    """
    Get the total count of activities matching the specified filters.
    
    Useful for pagination and displaying total counts in the UI.
    """
    try:
        # Parse filters (same logic as list_activities)
        from datetime import datetime
        from app.models.activity import ActivityCategory
        
        parsed_date_from = None
        parsed_date_to = None
        parsed_category = None
        
        if date_from:
            try:
                parsed_date_from = datetime.strptime(date_from, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date_from format. Use YYYY-MM-DD"
                )
        
        if date_to:
            try:
                parsed_date_to = datetime.strptime(date_to, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date_to format. Use YYYY-MM-DD"
                )
        
        if category:
            try:
                parsed_category = ActivityCategory(category)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category. Must be one of: {[c.value for c in ActivityCategory]}"
                )
        
        filters = ActivityFilters(
            category=parsed_category,
            tags=tags,
            date_from=parsed_date_from,
            date_to=parsed_date_to,
            impact_level_min=impact_level_min,
            impact_level_max=impact_level_max,
            search=search,
            limit=1,  # Not used for count
            offset=0  # Not used for count
        )
        
        count = await activity_service.get_activity_count(current_user.id, filters)
        return count
    
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )