"""
Export Schemas

Pydantic schemas for data export functionality.
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

from .activity import ActivityResponse
from .story import StoryResponse
from .report import ReportResponse
from .user import UserProfile


class ExportFormat(str, Enum):
    """Supported export formats."""
    JSON = "json"
    CSV = "csv"


class ExportRequest(BaseModel):
    """Request schema for data export."""
    format: ExportFormat = Field(..., description="Export format (json or csv)")
    include_activities: bool = Field(True, description="Include activities in export")
    include_stories: bool = Field(True, description="Include stories in export")
    include_reports: bool = Field(True, description="Include reports in export")
    include_user_profile: bool = Field(True, description="Include user profile in export")
    date_from: Optional[datetime] = Field(None, description="Start date for filtering data")
    date_to: Optional[datetime] = Field(None, description="End date for filtering data")


class ExportResponse(BaseModel):
    """Response schema for data export."""
    export_id: str = Field(..., description="Unique export identifier")
    download_url: str = Field(..., description="Secure download URL")
    expires_at: datetime = Field(..., description="URL expiration timestamp")
    file_size_bytes: int = Field(..., description="Export file size in bytes")
    format: ExportFormat = Field(..., description="Export format")
    created_at: datetime = Field(..., description="Export creation timestamp")


class ExportData(BaseModel):
    """Complete export data structure."""
    export_metadata: Dict[str, Any] = Field(..., description="Export metadata")
    user_profile: Optional[UserProfile] = Field(None, description="User profile data")
    activities: List[ActivityResponse] = Field(default_factory=list, description="User activities")
    stories: List[StoryResponse] = Field(default_factory=list, description="User stories")
    reports: List[ReportResponse] = Field(default_factory=list, description="User reports")


class ExportStatus(BaseModel):
    """Export status response."""
    export_id: str = Field(..., description="Export identifier")
    status: str = Field(..., description="Export status (pending, processing, complete, failed)")
    progress_percent: int = Field(..., description="Export progress percentage")
    message: Optional[str] = Field(None, description="Status message or error details")
    created_at: datetime = Field(..., description="Export creation timestamp")
    completed_at: Optional[datetime] = Field(None, description="Export completion timestamp")


class ImportRequest(BaseModel):
    """Request schema for data import."""
    validate_only: bool = Field(False, description="Only validate data without importing")
    overwrite_existing: bool = Field(False, description="Overwrite existing data with same IDs")
    import_activities: bool = Field(True, description="Import activities from data")
    import_stories: bool = Field(True, description="Import stories from data")
    import_reports: bool = Field(True, description="Import reports from data")


class ImportResponse(BaseModel):
    """Response schema for data import."""
    import_id: str = Field(..., description="Unique import identifier")
    status: str = Field(..., description="Import status (pending, processing, complete, failed)")
    validation_errors: List[str] = Field(default_factory=list, description="Validation error messages")
    imported_counts: Dict[str, int] = Field(default_factory=dict, description="Count of imported items by type")
    skipped_counts: Dict[str, int] = Field(default_factory=dict, description="Count of skipped items by type")
    created_at: datetime = Field(..., description="Import creation timestamp")


class BackupRequest(BaseModel):
    """Request schema for automated backup."""
    backup_type: str = Field(..., pattern="^(daily|weekly|monthly)$", description="Backup frequency type")
    retention_days: int = Field(30, ge=1, le=365, description="Number of days to retain backups")
    include_user_data: bool = Field(True, description="Include user profile in backup")


class BackupResponse(BaseModel):
    """Response schema for backup operations."""
    backup_id: str = Field(..., description="Unique backup identifier")
    backup_type: str = Field(..., description="Backup type")
    status: str = Field(..., description="Backup status")
    file_path: str = Field(..., description="Backup file location")
    file_size_bytes: int = Field(..., description="Backup file size")
    created_at: datetime = Field(..., description="Backup creation timestamp")
    expires_at: datetime = Field(..., description="Backup expiration timestamp")