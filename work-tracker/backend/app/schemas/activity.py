"""
Activity Schemas

Pydantic schemas for activity data validation and serialization.
"""

from typing import List, Optional, Dict, Any
from datetime import date, datetime
from pydantic import BaseModel, Field
from uuid import UUID

from app.models.activity import ActivityCategory


class ActivityBase(BaseModel):
    """Base activity schema with common fields."""
    title: str = Field(..., min_length=1, max_length=500)
    description: Optional[str] = None
    category: ActivityCategory
    tags: List[str] = Field(default_factory=list)
    impact_level: Optional[int] = Field(None, ge=1, le=5)
    date: date
    duration_minutes: Optional[int] = Field(None, ge=0)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ActivityCreate(ActivityBase):
    """Schema for creating a new activity."""
    pass


class ActivityUpdate(BaseModel):
    """Schema for updating activity information."""
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    description: Optional[str] = None
    category: Optional[ActivityCategory] = None
    tags: Optional[List[str]] = None
    impact_level: Optional[int] = Field(None, ge=1, le=5)
    date: Optional[date] = None
    duration_minutes: Optional[int] = Field(None, ge=0)
    metadata: Optional[Dict[str, Any]] = None


class ActivityResponse(ActivityBase):
    """Schema for activity response data."""
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ActivitySummary(BaseModel):
    """Schema for activity summary information."""
    id: UUID
    title: str
    category: ActivityCategory
    date: date
    impact_level: Optional[int]
    
    class Config:
        from_attributes = True


class ActivityFilters(BaseModel):
    """Schema for activity filtering parameters."""
    category: Optional[ActivityCategory] = None
    tags: Optional[List[str]] = None
    date_from: Optional[date] = None
    date_to: Optional[date] = None
    impact_level_min: Optional[int] = Field(None, ge=1, le=5)
    impact_level_max: Optional[int] = Field(None, ge=1, le=5)
    search: Optional[str] = None
    limit: int = Field(50, ge=1, le=100)
    offset: int = Field(0, ge=0)