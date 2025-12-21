"""
Reports Service API Router

Provides endpoints for report generation, management, and export.
"""
import logging
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, HTTPException, Depends, status, Query
from fastapi.responses import JSONResponse

from .service import get_reports_service, ReportsServiceError
from app.schemas.report import (
    ReportCreate, ReportUpdate, ReportResponse,
    ReportGenerationRequest, ReportExportRequest, ReportExportResponse
)
from app.models.report import ReportType, ReportStatus
from app.services.auth.jwt_middleware import get_current_user
from app.schemas.auth import User
from app.core.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.post("/", response_model=ReportResponse)
async def create_report(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new report.
    
    Args:
        report_data: Report creation data
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Created report
        
    Raises:
        HTTPException: If creation fails
    """
    try:
        reports_service = get_reports_service()
        report = await reports_service.create_report(db, current_user.id, report_data)
        
        return ReportResponse.from_orm(report)
        
    except ReportsServiceError as e:
        logger.error(f"Reports service error in create_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in create_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report creation"
        )


@router.get("/", response_model=List[ReportResponse])
async def list_reports(
    report_type: Optional[ReportType] = Query(None, description="Filter by report type"),
    status_filter: Optional[ReportStatus] = Query(None, alias="status", description="Filter by status"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of reports to return"),
    offset: int = Query(0, ge=0, description="Number of reports to skip"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List reports for the authenticated user.
    
    Args:
        report_type: Optional report type filter
        status_filter: Optional status filter
        limit: Maximum number of reports to return
        offset: Number of reports to skip
        current_user: Authenticated user
        db: Database session
        
    Returns:
        List of reports
    """
    try:
        reports_service = get_reports_service()
        reports = await reports_service.list_reports(
            db, current_user.id, report_type, status_filter, limit, offset
        )
        
        return [ReportResponse.from_orm(report) for report in reports]
        
    except Exception as e:
        logger.error(f"Unexpected error in list_reports: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report listing"
        )


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(
    report_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a specific report by ID.
    
    Args:
        report_id: ID of the report
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Report details
        
    Raises:
        HTTPException: If report not found
    """
    try:
        reports_service = get_reports_service()
        report = await reports_service.get_report(db, current_user.id, report_id)
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        return ReportResponse.from_orm(report)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in get_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report retrieval"
        )


@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(
    report_id: UUID,
    update_data: ReportUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update a report.
    
    Args:
        report_id: ID of the report to update
        update_data: Update data
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Updated report
        
    Raises:
        HTTPException: If update fails or report not found
    """
    try:
        reports_service = get_reports_service()
        report = await reports_service.update_report(db, current_user.id, report_id, update_data)
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        return ReportResponse.from_orm(report)
        
    except HTTPException:
        raise
    except ReportsServiceError as e:
        logger.error(f"Reports service error in update_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in update_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report update"
        )


@router.delete("/{report_id}")
async def delete_report(
    report_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a report.
    
    Args:
        report_id: ID of the report to delete
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Success message
        
    Raises:
        HTTPException: If deletion fails or report not found
    """
    try:
        reports_service = get_reports_service()
        deleted = await reports_service.delete_report(db, current_user.id, report_id)
        
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        return {"message": "Report deleted successfully"}
        
    except HTTPException:
        raise
    except ReportsServiceError as e:
        logger.error(f"Reports service error in delete_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in delete_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report deletion"
        )


@router.post("/generate", response_model=ReportResponse)
async def generate_ai_report(
    request: ReportGenerationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate a report using AI based on user activities.
    
    Args:
        request: Report generation request
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Generated report
        
    Raises:
        HTTPException: If generation fails
    """
    try:
        reports_service = get_reports_service()
        report = await reports_service.generate_ai_report(db, current_user.id, request)
        
        logger.info(f"AI report generated for user {current_user.id}: {report.id}")
        return ReportResponse.from_orm(report)
        
    except ReportsServiceError as e:
        logger.error(f"Reports service error in generate_ai_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Report generation service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in generate_ai_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report generation"
        )


@router.post("/export", response_model=ReportExportResponse)
async def export_report(
    request: ReportExportRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Export a report in the specified format.
    
    Args:
        request: Export request
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Export response with download information
        
    Raises:
        HTTPException: If export fails
    """
    try:
        reports_service = get_reports_service()
        export_response = await reports_service.export_report(db, current_user.id, request)
        
        logger.info(f"Report exported for user {current_user.id}: {request.report_id}")
        return export_response
        
    except ReportsServiceError as e:
        logger.error(f"Reports service error in export_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in export_report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report export"
        )