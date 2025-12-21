"""
Story Schemas

Pydantic schemas for story data validation and serialization.
"""

from typing import List, Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field
from uuid import UUID

from app.models.story import StoryStatus


class StoryBase(BaseModel):
    """Base story schema with common fields."""
    title: str = Field(..., min_length=1, max_length=500)
    situation: str = Field(..., min_length=1)
    task: str = Field(..., min_length=1)
    action: str = Field(..., min_length=1)
    result: str = Field(..., min_length=1)
    impact_metrics: Dict[str, Any] = Field(default_factory=dict)
    tags: List[str] = Field(default_factory=list)


class StoryCreate(StoryBase):
    """Schema for creating a new story."""
    status: Optional[StoryStatus] = StoryStatus.DRAFT


class StoryUpdate(BaseModel):
    """Schema for updating story information."""
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    situation: Optional[str] = Field(None, min_length=1)
    task: Optional[str] = Field(None, min_length=1)
    action: Optional[str] = Field(None, min_length=1)
    result: Optional[str] = Field(None, min_length=1)
    impact_metrics: Optional[Dict[str, Any]] = None
    tags: Optional[List[str]] = None
    status: Optional[StoryStatus] = None


class StoryResponse(StoryBase):
    """Schema for story response data."""
    id: UUID
    user_id: UUID
    status: StoryStatus
    ai_enhanced: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class StorySummary(BaseModel):
    """Schema for story summary information."""
    id: UUID
    title: str
    status: StoryStatus
    ai_enhanced: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class StoryFilters(BaseModel):
    """Schema for story filtering parameters."""
    status: Optional[StoryStatus] = None
    tags: Optional[List[str]] = None
    ai_enhanced: Optional[bool] = None
    search: Optional[str] = None
    limit: int = Field(50, ge=1, le=100)
    offset: int = Field(0, ge=0)


class StoryEnhancementRequest(BaseModel):
    """Schema for AI story enhancement requests."""
    story_id: UUID
    enhancement_type: str = Field(..., regex="^(improve|quantify|complete)$")
    focus_areas: Optional[List[str]] = None


class StoryEnhancementResponse(BaseModel):
    """Schema for AI story enhancement responses."""
    original_content: Dict[str, str]
    enhanced_content: Dict[str, str]
    suggestions: List[str]
    confidence_score: float = Field(..., ge=0.0, le=1.0)