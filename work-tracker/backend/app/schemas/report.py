"""
Report Schemas

Pydantic schemas for report data validation and serialization.
"""

from typing import List, Optional
from datetime import date, datetime
from pydantic import BaseModel, Field
from uuid import UUID

from app.models.report import ReportType, ReportStatus


class ReportBase(BaseModel):
    """Base report schema with common fields."""
    title: str = Field(..., min_length=1, max_length=500)
    period_start: date
    period_end: date
    report_type: ReportType


class ReportCreate(ReportBase):
    """Schema for creating a new report."""
    content: Optional[str] = None
    activities_included: Optional[List[UUID]] = Field(default_factory=list)
    stories_included: Optional[List[UUID]] = Field(default_factory=list)


class ReportUpdate(BaseModel):
    """Schema for updating report information."""
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    content: Optional[str] = None
    status: Optional[ReportStatus] = None
    activities_included: Optional[List[UUID]] = None
    stories_included: Optional[List[UUID]] = None


class ReportResponse(ReportBase):
    """Schema for report response data."""
    id: UUID
    user_id: UUID
    content: Optional[str]
    activities_included: List[UUID]
    stories_included: List[UUID]
    generated_by_ai: bool
    status: ReportStatus
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ReportSummary(BaseModel):
    """Schema for report summary information."""
    id: UUID
    title: str
    report_type: ReportType
    period_start: date
    period_end: date
    status: ReportStatus
    created_at: datetime
    
    class Config:
        from_attributes = True


class ReportFilters(BaseModel):
    """Schema for report filtering parameters."""
    report_type: Optional[ReportType] = None
    status: Optional[ReportStatus] = None
    period_start: Optional[date] = None
    period_end: Optional[date] = None
    limit: int = Field(50, ge=1, le=100)
    offset: int = Field(0, ge=0)


class ReportGenerationRequest(BaseModel):
    """Schema for report generation requests."""
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    period_start: date
    period_end: date
    report_type: ReportType
    custom_instructions: Optional[str] = None
    include_activities: bool = True
    include_stories: bool = True
    activity_categories: Optional[List[str]] = None
    story_tags: Optional[List[str]] = None


class ReportExportRequest(BaseModel):
    """Schema for report export requests."""
    report_id: UUID
    format: str = Field(..., pattern="^(pdf|docx|html)$")
    include_charts: bool = True
    include_raw_data: bool = False


class ReportExportResponse(BaseModel):
    """Schema for report export responses."""
    report_id: UUID
    format: str
    download_url: str
    expires_at: datetime
    file_size: int