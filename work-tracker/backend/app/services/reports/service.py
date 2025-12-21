"""
Reports Service

Handles report generation, management, and export functionality.
Integrates with AI service for automated report generation.
"""
import logging
from typing import List, Optional, Dict, Any
from datetime import date, datetime
from uuid import UUID, uuid4
import asyncio

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models.report import Report, ReportType, ReportStatus
from app.models.activity import Activity
from app.models.story import Story
from app.schemas.report import (
    ReportCreate, ReportUpdate, ReportResponse,
    ReportGenerationRequest as ReportGenRequest,
    ReportExportRequest, ReportExportResponse
)
from app.services.ai.service import get_ai_service, AIServiceError
from app.services.ai.schemas import (
    ReportGenerationRequest, ActivitySummary,
    ReportGenerationResponse
)

logger = logging.getLogger(__name__)


class ReportsServiceError(Exception):
    """Custom exception for reports service errors."""
    pass


class ReportsService:
    """Service for managing reports and AI-powered report generation."""
    
    def __init__(self):
        """Initialize reports service."""
        self.ai_service = get_ai_service()
    
    async def create_report(
        self, 
        db: AsyncSession, 
        user_id: UUID, 
        report_data: ReportCreate
    ) -> Report:
        """
        Create a new report.
        
        Args:
            db: Database session
            user_id: ID of the user creating the report
            report_data: Report creation data
            
        Returns:
            Created report
            
        Raises:
            ReportsServiceError: If creation fails
        """
        try:
            report = Report(
                id=uuid4(),
                user_id=user_id,
                title=report_data.title,
                period_start=report_data.period_start,
                period_end=report_data.period_end,
                report_type=report_data.report_type,
                content=report_data.content or "",
                activities_included=report_data.activities_included or [],
                stories_included=report_data.stories_included or [],
                generated_by_ai=False,
                status=ReportStatus.DRAFT,
                created_at=datetime.utcnow()
            )
            
            db.add(report)
            await db.commit()
            await db.refresh(report)
            
            logger.info(f"Report created: {report.id} for user {user_id}")
            return report
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Failed to create report: {e}")
            raise ReportsServiceError(f"Failed to create report: {e}")
    
    async def get_report(
        self, 
        db: AsyncSession, 
        user_id: UUID, 
        report_id: UUID
    ) -> Optional[Report]:
        """
        Get a report by ID for a specific user.
        
        Args:
            db: Database session
            user_id: ID of the user
            report_id: ID of the report
            
        Returns:
            Report if found, None otherwise
        """
        try:
            result = await db.execute(
                select(Report).where(
                    and_(Report.id == report_id, Report.user_id == user_id)
                )
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get report {report_id}: {e}")
            return None
    
    async def list_reports(
        self, 
        db: AsyncSession, 
        user_id: UUID,
        report_type: Optional[ReportType] = None,
        status: Optional[ReportStatus] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Report]:
        """
        List reports for a user with optional filtering.
        
        Args:
            db: Database session
            user_id: ID of the user
            report_type: Optional report type filter
            status: Optional status filter
            limit: Maximum number of reports to return
            offset: Number of reports to skip
            
        Returns:
            List of reports
        """
        try:
            query = select(Report).where(Report.user_id == user_id)
            
            if report_type:
                query = query.where(Report.report_type == report_type)
            if status:
                query = query.where(Report.status == status)
            
            query = query.order_by(Report.created_at.desc()).limit(limit).offset(offset)
            
            result = await db.execute(query)
            return result.scalars().all()
            
        except Exception as e:
            logger.error(f"Failed to list reports for user {user_id}: {e}")
            return []
    
    async def update_report(
        self, 
        db: AsyncSession, 
        user_id: UUID, 
        report_id: UUID,
        update_data: ReportUpdate
    ) -> Optional[Report]:
        """
        Update a report.
        
        Args:
            db: Database session
            user_id: ID of the user
            report_id: ID of the report to update
            update_data: Update data
            
        Returns:
            Updated report if successful, None otherwise
            
        Raises:
            ReportsServiceError: If update fails
        """
        try:
            report = await self.get_report(db, user_id, report_id)
            if not report:
                return None
            
            # Update fields
            if update_data.title is not None:
                report.title = update_data.title
            if update_data.content is not None:
                report.content = update_data.content
            if update_data.status is not None:
                report.status = update_data.status
            if update_data.activities_included is not None:
                report.activities_included = update_data.activities_included
            if update_data.stories_included is not None:
                report.stories_included = update_data.stories_included
            
            await db.commit()
            await db.refresh(report)
            
            logger.info(f"Report updated: {report_id}")
            return report
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Failed to update report {report_id}: {e}")
            raise ReportsServiceError(f"Failed to update report: {e}")
    
    async def delete_report(
        self, 
        db: AsyncSession, 
        user_id: UUID, 
        report_id: UUID
    ) -> bool:
        """
        Delete a report.
        
        Args:
            db: Database session
            user_id: ID of the user
            report_id: ID of the report to delete
            
        Returns:
            True if deleted, False if not found
            
        Raises:
            ReportsServiceError: If deletion fails
        """
        try:
            report = await self.get_report(db, user_id, report_id)
            if not report:
                return False
            
            await db.delete(report)
            await db.commit()
            
            logger.info(f"Report deleted: {report_id}")
            return True
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Failed to delete report {report_id}: {e}")
            raise ReportsServiceError(f"Failed to delete report: {e}")
    
    async def generate_ai_report(
        self, 
        db: AsyncSession, 
        user_id: UUID,
        request: ReportGenRequest
    ) -> Report:
        """
        Generate a report using AI based on user activities.
        
        Args:
            db: Database session
            user_id: ID of the user
            request: Report generation request
            
        Returns:
            Generated report
            
        Raises:
            ReportsServiceError: If generation fails
        """
        try:
            # Fetch activities for the specified period
            activities = await self._get_activities_for_period(
                db, user_id, request.period_start, request.period_end
            )
            
            if not activities:
                raise ReportsServiceError("No activities found for the specified period")
            
            # Convert activities to AI service format
            activity_summaries = [
                ActivitySummary(
                    title=activity.title,
                    category=activity.category.value,
                    date=activity.date,
                    description=activity.description or "",
                    impact_level=activity.impact_level or 3,
                    tags=activity.tags or [],
                    duration_minutes=activity.duration_minutes
                )
                for activity in activities
            ]
            
            # Generate report using AI service
            ai_request = ReportGenerationRequest(
                activities=activity_summaries,
                period_start=request.period_start,
                period_end=request.period_end,
                report_type=request.report_type.value,
                custom_instructions=request.custom_instructions
            )
            
            ai_response = await self.ai_service.generate_report(ai_request)
            
            # Create report in database
            report_data = ReportCreate(
                title=request.title or f"{request.report_type.value.title()} Report - {request.period_start} to {request.period_end}",
                period_start=request.period_start,
                period_end=request.period_end,
                report_type=request.report_type,
                content=ai_response.report_content,
                activities_included=[activity.id for activity in activities],
                stories_included=[]  # TODO: Include relevant stories
            )
            
            report = await self.create_report(db, user_id, report_data)
            
            # Mark as AI-generated
            report.generated_by_ai = True
            report.status = ReportStatus.COMPLETE
            await db.commit()
            await db.refresh(report)
            
            logger.info(
                f"AI report generated: {report.id} for user {user_id}, "
                f"activities: {len(activities)}, words: {ai_response.word_count}"
            )
            
            return report
            
        except AIServiceError as e:
            logger.error(f"AI service error in report generation: {e}")
            raise ReportsServiceError(f"AI report generation failed: {e}")
        except Exception as e:
            logger.error(f"Failed to generate AI report: {e}")
            raise ReportsServiceError(f"Report generation failed: {e}")
    
    async def _get_activities_for_period(
        self, 
        db: AsyncSession, 
        user_id: UUID,
        start_date: date,
        end_date: date
    ) -> List[Activity]:
        """
        Get activities for a user within a date range.
        
        Args:
            db: Database session
            user_id: ID of the user
            start_date: Start date of the period
            end_date: End date of the period
            
        Returns:
            List of activities
        """
        try:
            result = await db.execute(
                select(Activity).where(
                    and_(
                        Activity.user_id == user_id,
                        Activity.date >= start_date,
                        Activity.date <= end_date
                    )
                ).order_by(Activity.date.desc())
            )
            return result.scalars().all()
        except Exception as e:
            logger.error(f"Failed to get activities for period: {e}")
            return []
    
    async def export_report(
        self, 
        db: AsyncSession, 
        user_id: UUID,
        request: ReportExportRequest
    ) -> ReportExportResponse:
        """
        Export a report in the specified format.
        
        Args:
            db: Database session
            user_id: ID of the user
            request: Export request
            
        Returns:
            Export response with download information
            
        Raises:
            ReportsServiceError: If export fails
        """
        try:
            report = await self.get_report(db, user_id, request.report_id)
            if not report:
                raise ReportsServiceError("Report not found")
            
            # For now, return the content as-is
            # TODO: Implement actual PDF/Word generation
            export_content = report.content
            
            # Generate a temporary download URL (mock implementation)
            download_url = f"/api/v1/reports/{report.id}/download?format={request.format}"
            
            return ReportExportResponse(
                report_id=report.id,
                format=request.format,
                download_url=download_url,
                expires_at=datetime.utcnow().replace(hour=23, minute=59, second=59),  # End of day
                file_size=len(export_content.encode('utf-8'))
            )
            
        except Exception as e:
            logger.error(f"Failed to export report {request.report_id}: {e}")
            raise ReportsServiceError(f"Report export failed: {e}")


# Global service instance
_reports_service: Optional[ReportsService] = None


def get_reports_service() -> ReportsService:
    """Get or create the global reports service instance."""
    global _reports_service
    if _reports_service is None:
        _reports_service = ReportsService()
    return _reports_service