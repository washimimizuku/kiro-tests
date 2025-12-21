"""
Story Router

FastAPI router for story management endpoints.
"""

from typing import List, Dict, Any
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.services.auth.jwt_middleware import get_current_user
from app.services.stories.service import StoryService
from app.schemas.story import (
    StoryCreate, StoryUpdate, StoryResponse, StorySummary,
    StoryFilters, StoryEnhancementRequest
)
from app.schemas.user import UserResponse
from app.models.story import StoryStatus


router = APIRouter(prefix="/stories", tags=["stories"])


def get_story_service(db: Session = Depends(get_db)) -> StoryService:
    """Dependency to get story service instance."""
    return StoryService(db)


@router.post("/", response_model=StoryResponse, status_code=status.HTTP_201_CREATED)
async def create_story(
    story_data: StoryCreate,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Create a new story with STAR format validation."""
    try:
        story = await story_service.create_story(current_user.id, story_data)
        return StoryResponse.from_orm(story)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create story: {str(e)}"
        )


@router.get("/", response_model=List[StoryResponse])
async def list_stories(
    filters: StoryFilters = Depends(),
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """List stories with filtering and pagination."""
    try:
        stories = await story_service.list_stories(current_user.id, filters)
        return [StoryResponse.from_orm(story) for story in stories]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve stories: {str(e)}"
        )


@router.get("/summaries", response_model=List[StorySummary])
async def get_story_summaries(
    limit: int = 10,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Get recent story summaries for dashboard display."""
    try:
        summaries = await story_service.get_story_summaries(current_user.id, limit)
        return summaries
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve story summaries: {str(e)}"
        )


@router.get("/tags", response_model=List[str])
async def get_story_tags(
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Get all unique tags used by the user's stories."""
    try:
        tags = await story_service.get_story_tags(current_user.id)
        return tags
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve story tags: {str(e)}"
        )


@router.get("/search", response_model=List[StoryResponse])
async def search_stories(
    q: str,
    limit: int = 20,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Advanced search functionality for stories."""
    if not q or len(q.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query must be at least 2 characters long"
        )
    
    try:
        stories = await story_service.search_stories(current_user.id, q.strip(), limit)
        return [StoryResponse.from_orm(story) for story in stories]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to search stories: {str(e)}"
        )


@router.get("/{story_id}", response_model=StoryResponse)
async def get_story(
    story_id: UUID,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Retrieve a specific story by ID."""
    story = await story_service.get_story(current_user.id, story_id)
    if not story:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Story not found"
        )
    
    return StoryResponse.from_orm(story)


@router.put("/{story_id}", response_model=StoryResponse)
async def update_story(
    story_id: UUID,
    story_data: StoryUpdate,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Update an existing story."""
    try:
        story = await story_service.update_story(current_user.id, story_id, story_data)
        if not story:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Story not found"
            )
        
        return StoryResponse.from_orm(story)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update story: {str(e)}"
        )


@router.put("/{story_id}/status", response_model=StoryResponse)
async def update_story_status(
    story_id: UUID,
    status: StoryStatus,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Update story status with validation."""
    try:
        story = await story_service.update_story_status(current_user.id, story_id, status)
        if not story:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Story not found"
            )
        
        return StoryResponse.from_orm(story)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update story status: {str(e)}"
        )


@router.delete("/{story_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_story(
    story_id: UUID,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Delete a story."""
    success = await story_service.delete_story(current_user.id, story_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Story not found"
        )



@router.get("/categories", response_model=Dict[str, int])
async def get_story_categories(
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Get story categories with counts for the user."""
    try:
        categories = await story_service.get_story_categories(current_user.id)
        return categories
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve story categories: {str(e)}"
        )


@router.put("/{story_id}/impact-metrics", response_model=StoryResponse)
async def update_story_impact_metrics(
    story_id: UUID,
    metrics: Dict[str, Any],
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Update story impact metrics."""
    try:
        story = await story_service.update_story_impact_metrics(current_user.id, story_id, metrics)
        if not story:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Story not found"
            )
        
        return StoryResponse.from_orm(story)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update impact metrics: {str(e)}"
        )


@router.get("/templates", response_model=List[Dict[str, Any]])
async def get_story_templates(
    story_service: StoryService = Depends(get_story_service)
):
    """Get predefined story templates for different scenarios."""
    try:
        templates = await story_service.get_story_templates()
        return templates
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve story templates: {str(e)}"
        )


@router.get("/{story_id}/guidance", response_model=Dict[str, Any])
async def get_story_guidance(
    story_id: UUID,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Get guidance and suggestions for improving a story."""
    try:
        guidance = await story_service.get_story_guidance(story_id, current_user.id)
        if not guidance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Story not found"
            )
        
        return guidance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve story guidance: {str(e)}"
        )


@router.put("/tags/bulk-update", response_model=Dict[str, int])
async def bulk_update_story_tags(
    old_tag: str,
    new_tag: str,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Bulk update story tags (rename or merge tags)."""
    if not old_tag or not new_tag:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Both old_tag and new_tag must be provided"
        )
    
    try:
        updated_count = await story_service.bulk_update_story_tags(current_user.id, old_tag, new_tag)
        return {"updated_count": updated_count}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to bulk update tags: {str(e)}"
        )


@router.delete("/tags/{tag}", response_model=Dict[str, int])
async def delete_story_tag(
    tag: str,
    current_user: UserResponse = Depends(get_current_user),
    story_service: StoryService = Depends(get_story_service)
):
    """Remove a tag from all user stories."""
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tag must be provided"
        )
    
    try:
        updated_count = await story_service.delete_story_tag(current_user.id, tag)
        return {"updated_count": updated_count}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete tag: {str(e)}"
        )
