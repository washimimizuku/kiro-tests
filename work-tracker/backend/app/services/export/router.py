"""
Export Router

FastAPI router for data export endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any
import uuid
import io

from app.core.database import get_db
from app.services.auth.jwt_middleware import get_current_user
from app.schemas.export import ExportRequest, ExportResponse, ImportRequest, ImportResponse, BackupRequest, BackupResponse
from .service import ExportService

router = APIRouter()


@router.post("/", response_model=ExportResponse)
async def create_export(
    export_request: ExportRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a data export for the current user.
    
    This endpoint generates a comprehensive export of the user's data
    in the requested format (JSON or CSV) and returns a secure download URL.
    """
    try:
        export_service = ExportService(db)
        export_response = await export_service.create_export(
            user_id=current_user["sub"],  # Use sub claim for user ID
            export_request=export_request
        )
        return export_response
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create export: {str(e)}"
        )


@router.get("/download/{export_id}")
async def download_export(
    export_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Download an export file.
    
    This endpoint provides secure download access to previously generated
    export files. The export_id must belong to the current user.
    """
    try:
        export_service = ExportService(db)
        
        # For this implementation, we'll regenerate the export
        # In production, this would retrieve from S3
        
        # Determine format and generate appropriate response
        if export_id.endswith('.json'):
            # Generate JSON export
            from app.schemas.export import ExportFormat
            export_request = ExportRequest(
                format=ExportFormat.JSON,
                include_activities=True,
                include_stories=True,
                include_reports=True,
                include_user_profile=True
            )
            
            export_data = await export_service._collect_export_data(
                current_user["sub"], export_request
            )
            file_content, _ = await export_service._generate_export_file(
                export_data, ExportFormat.JSON
            )
            
            return Response(
                content=file_content,
                media_type="application/json",
                headers={
                    "Content-Disposition": f"attachment; filename=work_tracker_export_{current_user['sub']}.json"
                }
            )
            
        elif export_id.endswith('.csv'):
            # Generate CSV export
            from app.schemas.export import ExportFormat
            export_request = ExportRequest(
                format=ExportFormat.CSV,
                include_activities=True,
                include_stories=True,
                include_reports=True,
                include_user_profile=True
            )
            
            export_data = await export_service._collect_export_data(
                current_user["sub"], export_request
            )
            file_content, _ = await export_service._generate_export_file(
                export_data, ExportFormat.CSV
            )
            
            return Response(
                content=file_content,
                media_type="text/csv",
                headers={
                    "Content-Disposition": f"attachment; filename=work_tracker_export_{current_user['sub']}.csv"
                }
            )
        else:
            raise HTTPException(
                status_code=400,
                detail="Invalid export format"
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to download export: {str(e)}"
        )


@router.get("/formats")
async def get_export_formats():
    """
    Get available export formats.
    
    Returns a list of supported export formats and their descriptions.
    """
    return {
        "formats": [
            {
                "format": "json",
                "description": "Complete data export in JSON format with full metadata",
                "mime_type": "application/json",
                "file_extension": ".json"
            },
            {
                "format": "csv",
                "description": "Tabular data export in CSV format for spreadsheet applications",
                "mime_type": "text/csv",
                "file_extension": ".csv"
            }
        ]
    }


@router.post("/import", response_model=ImportResponse)
async def import_data(
    import_data: Dict[str, Any],
    import_request: ImportRequest = ImportRequest(),
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Import user data from a previously exported data structure.
    
    This endpoint allows users to import their data back into the system,
    useful for data migration or restoring from backups.
    """
    try:
        export_service = ExportService(db)
        import_response = await export_service.import_data(
            user_id=current_user["sub"],
            import_data=import_data,
            import_request=import_request
        )
        return import_response
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to import data: {str(e)}"
        )


@router.post("/backup", response_model=BackupResponse)
async def create_backup(
    backup_request: BackupRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create an automated backup of user data.
    
    This endpoint creates a backup of the user's data with configurable
    retention policies for automated backup scheduling.
    """
    try:
        export_service = ExportService(db)
        backup_response = await export_service.create_backup(
            user_id=current_user["sub"],
            backup_request=backup_request
        )
        return backup_response
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create backup: {str(e)}"
        )