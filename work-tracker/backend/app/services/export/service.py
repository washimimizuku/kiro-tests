"""
Export Service

Service for handling data export functionality including JSON and CSV formats.
"""

import json
import csv
import io
import uuid
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import and_, select

from app.models import User, Activity, Story, Report
from app.schemas.export import ExportRequest, ExportResponse, ExportData, ExportFormat, ImportRequest, ImportResponse, BackupRequest, BackupResponse
from app.schemas.activity import ActivityResponse
from app.schemas.story import StoryResponse
from app.schemas.report import ReportResponse
from app.schemas.user import UserProfile


class ExportService:
    """Service for data export operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_export(
        self,
        user_id: uuid.UUID,
        export_request: ExportRequest
    ) -> ExportResponse:
        """
        Create a data export for the user.
        
        Args:
            user_id: User ID requesting the export
            export_request: Export configuration
            
        Returns:
            ExportResponse with download URL and metadata
        """
        # Generate unique export ID
        export_id = str(uuid.uuid4())
        
        # Collect data based on request
        export_data = await self._collect_export_data(user_id, export_request)
        
        # Generate export file
        file_content, file_size = await self._generate_export_file(
            export_data,
            export_request.format
        )
        
        # Store export file (in production, this would be S3)
        # For now, we'll simulate with a temporary storage
        file_path = await self._store_export_file(export_id, file_content, export_request.format)
        
        # Generate secure download URL with expiration
        download_url = await self._generate_download_url(export_id, export_request.format)
        expires_at = datetime.utcnow() + timedelta(hours=24)
        
        return ExportResponse(
            export_id=export_id,
            download_url=download_url,
            expires_at=expires_at,
            file_size_bytes=file_size,
            format=export_request.format,
            created_at=datetime.utcnow()
        )
    
    async def _collect_export_data(
        self,
        user_id: uuid.UUID,
        export_request: ExportRequest
    ) -> ExportData:
        """Collect all requested data for export."""
        export_metadata = {
            "export_version": "1.0",
            "export_date": datetime.utcnow().isoformat(),
            "user_id": str(user_id),
            "filters": {
                "date_from": export_request.date_from.isoformat() if export_request.date_from else None,
                "date_to": export_request.date_to.isoformat() if export_request.date_to else None,
            }
        }
        
        # Get user profile
        user_profile = None
        if export_request.include_user_profile:
            result = await self.db.execute(
                select(User).where(User.id == user_id)
            )
            user = result.scalar_one_or_none()
            if user:
                user_profile = UserProfile(
                    id=user.id,
                    email=user.email,
                    name=user.name,
                    preferences=user.preferences,
                    created_at=user.created_at,
                    updated_at=user.updated_at
                )
        
        # Get activities
        activities = []
        if export_request.include_activities:
            query = select(Activity).where(Activity.user_id == user_id)
            
            # Apply date filters
            if export_request.date_from:
                query = query.where(Activity.date >= export_request.date_from.date())
            if export_request.date_to:
                query = query.where(Activity.date <= export_request.date_to.date())
            
            query = query.order_by(Activity.date.desc())
            result = await self.db.execute(query)
            activities_data = result.scalars().all()
            
            activities = [
                ActivityResponse(
                    id=a.id,
                    user_id=a.user_id,
                    title=a.title,
                    description=a.description,
                    category=a.category,
                    tags=a.tags or [],
                    impact_level=a.impact_level,
                    date=a.date,
                    duration_minutes=a.duration_minutes,
                    metadata=a.metadata_json or {},
                    created_at=a.created_at,
                    updated_at=a.updated_at
                )
                for a in activities_data
            ]
        
        # Get stories
        stories = []
        if export_request.include_stories:
            query = select(Story).where(Story.user_id == user_id)
            
            # Apply date filters based on creation date
            if export_request.date_from:
                query = query.where(Story.created_at >= export_request.date_from)
            if export_request.date_to:
                query = query.where(Story.created_at <= export_request.date_to)
            
            query = query.order_by(Story.created_at.desc())
            result = await self.db.execute(query)
            stories_data = result.scalars().all()
            
            stories = [
                StoryResponse(
                    id=s.id,
                    user_id=s.user_id,
                    title=s.title,
                    situation=s.situation,
                    task=s.task,
                    action=s.action,
                    result=s.result,
                    impact_metrics=s.impact_metrics or {},
                    tags=s.tags or [],
                    status=s.status,
                    ai_enhanced=s.ai_enhanced,
                    created_at=s.created_at,
                    updated_at=s.updated_at
                )
                for s in stories_data
            ]
        
        # Get reports
        reports = []
        if export_request.include_reports:
            query = select(Report).where(Report.user_id == user_id)
            
            # Apply date filters based on report period
            if export_request.date_from:
                query = query.where(Report.period_end >= export_request.date_from.date())
            if export_request.date_to:
                query = query.where(Report.period_start <= export_request.date_to.date())
            
            query = query.order_by(Report.created_at.desc())
            result = await self.db.execute(query)
            reports_data = result.scalars().all()
            
            reports = [
                ReportResponse(
                    id=r.id,
                    user_id=r.user_id,
                    title=r.title,
                    period_start=r.period_start,
                    period_end=r.period_end,
                    report_type=r.report_type,
                    content=r.content,
                    activities_included=r.activities_included or [],
                    stories_included=r.stories_included or [],
                    generated_by_ai=r.generated_by_ai,
                    status=r.status,
                    created_at=r.created_at,
                    updated_at=r.updated_at
                )
                for r in reports_data
            ]
        
        return ExportData(
            export_metadata=export_metadata,
            user_profile=user_profile,
            activities=activities,
            stories=stories,
            reports=reports
        )
    
    async def _generate_export_file(
        self,
        export_data: ExportData,
        format: ExportFormat
    ) -> tuple[bytes, int]:
        """Generate export file in the requested format."""
        if format == ExportFormat.JSON:
            return await self._generate_json_export(export_data)
        elif format == ExportFormat.CSV:
            return await self._generate_csv_export(export_data)
        else:
            raise ValueError(f"Unsupported export format: {format}")
    
    async def _generate_json_export(self, export_data: ExportData) -> tuple[bytes, int]:
        """Generate JSON export file."""
        # Convert Pydantic models to dict
        export_dict = export_data.model_dump(mode='json')
        
        # Convert to JSON string with pretty printing
        json_str = json.dumps(export_dict, indent=2, default=str)
        json_bytes = json_str.encode('utf-8')
        
        return json_bytes, len(json_bytes)
    
    async def _generate_csv_export(self, export_data: ExportData) -> tuple[bytes, int]:
        """Generate CSV export file (activities, stories, and reports in separate sections)."""
        output = io.StringIO()
        
        # Write metadata
        output.write("# Export Metadata\n")
        for key, value in export_data.export_metadata.items():
            output.write(f"# {key}: {value}\n")
        output.write("\n")
        
        # Write user profile
        if export_data.user_profile:
            output.write("# User Profile\n")
            writer = csv.DictWriter(output, fieldnames=['id', 'email', 'name', 'created_at', 'updated_at'])
            writer.writeheader()
            writer.writerow({
                'id': str(export_data.user_profile.id),
                'email': export_data.user_profile.email,
                'name': export_data.user_profile.name,
                'created_at': export_data.user_profile.created_at,
                'updated_at': export_data.user_profile.updated_at
            })
            output.write("\n")
        
        # Write activities
        if export_data.activities:
            output.write("# Activities\n")
            fieldnames = ['id', 'title', 'description', 'category', 'tags', 'impact_level', 'date', 'duration_minutes', 'created_at']
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            for activity in export_data.activities:
                writer.writerow({
                    'id': str(activity.id),
                    'title': activity.title,
                    'description': activity.description or '',
                    'category': activity.category,
                    'tags': ','.join(activity.tags) if activity.tags else '',
                    'impact_level': activity.impact_level or '',
                    'date': activity.date,
                    'duration_minutes': activity.duration_minutes or '',
                    'created_at': activity.created_at
                })
            output.write("\n")
        
        # Write stories
        if export_data.stories:
            output.write("# Stories\n")
            fieldnames = ['id', 'title', 'situation', 'task', 'action', 'result', 'tags', 'status', 'ai_enhanced', 'created_at']
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            for story in export_data.stories:
                writer.writerow({
                    'id': str(story.id),
                    'title': story.title,
                    'situation': story.situation,
                    'task': story.task,
                    'action': story.action,
                    'result': story.result,
                    'tags': ','.join(story.tags) if story.tags else '',
                    'status': story.status,
                    'ai_enhanced': story.ai_enhanced,
                    'created_at': story.created_at
                })
            output.write("\n")
        
        # Write reports
        if export_data.reports:
            output.write("# Reports\n")
            fieldnames = ['id', 'title', 'period_start', 'period_end', 'report_type', 'status', 'generated_by_ai', 'created_at']
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            for report in export_data.reports:
                writer.writerow({
                    'id': str(report.id),
                    'title': report.title,
                    'period_start': report.period_start,
                    'period_end': report.period_end,
                    'report_type': report.report_type,
                    'status': report.status,
                    'generated_by_ai': report.generated_by_ai,
                    'created_at': report.created_at
                })
        
        csv_str = output.getvalue()
        csv_bytes = csv_str.encode('utf-8')
        
        return csv_bytes, len(csv_bytes)
    
    async def _store_export_file(
        self,
        export_id: str,
        file_content: bytes,
        format: ExportFormat
    ) -> str:
        """
        Store export file.
        In production, this would upload to S3.
        For now, we'll simulate with a file path.
        """
        # In production: upload to S3 and return S3 key
        # For now, return a simulated path
        extension = "json" if format == ExportFormat.JSON else "csv"
        file_path = f"/tmp/exports/{export_id}.{extension}"
        
        # In a real implementation, we would:
        # s3_client.put_object(Bucket=bucket, Key=file_path, Body=file_content)
        
        return file_path
    
    async def _generate_download_url(
        self,
        export_id: str,
        format: ExportFormat
    ) -> str:
        """
        Generate secure download URL.
        In production, this would be a pre-signed S3 URL.
        """
        # In production: generate pre-signed S3 URL with expiration
        # For now, return a simulated URL
        extension = "json" if format == ExportFormat.JSON else "csv"
        return f"/api/v1/export/download/{export_id}.{extension}"
    
    async def get_export_file(
        self,
        export_id: str,
        user_id: uuid.UUID
    ) -> tuple[bytes, str]:
        """
        Retrieve export file for download.
        
        Args:
            export_id: Export identifier
            user_id: User ID (for authorization)
            
        Returns:
            Tuple of (file_content, content_type)
        """
        # In production, this would retrieve from S3
        # For now, we'll regenerate the export
        # This is a simplified implementation
        
        # Determine format from export_id
        if export_id.endswith('.json'):
            format = ExportFormat.JSON
            content_type = "application/json"
        elif export_id.endswith('.csv'):
            format = ExportFormat.CSV
            content_type = "text/csv"
        else:
            raise ValueError("Invalid export ID format")
        
        # For this implementation, we'll return a placeholder
        # In production, retrieve from S3
        return b"", content_type
    
    async def import_data(
        self,
        user_id: uuid.UUID,
        import_data: Dict[str, Any],
        import_request: ImportRequest
    ) -> ImportResponse:
        """
        Import user data from a previously exported data structure.
        
        Args:
            user_id: User ID for the import
            import_data: Parsed import data (from JSON export)
            import_request: Import configuration
            
        Returns:
            ImportResponse with import results
        """
        import_id = str(uuid.uuid4())
        validation_errors = []
        imported_counts = {"activities": 0, "stories": 0, "reports": 0}
        skipped_counts = {"activities": 0, "stories": 0, "reports": 0}
        
        try:
            # Validate import data structure
            if "export_metadata" not in import_data:
                validation_errors.append("Missing export_metadata in import data")
            
            # Validate user ownership (import data should belong to the same user)
            if "export_metadata" in import_data:
                exported_user_id = import_data["export_metadata"].get("user_id")
                if exported_user_id and str(user_id) != exported_user_id:
                    validation_errors.append(f"Import data belongs to different user: {exported_user_id}")
            
            # If validation only, return early
            if import_request.validate_only:
                return ImportResponse(
                    import_id=import_id,
                    status="validated",
                    validation_errors=validation_errors,
                    imported_counts=imported_counts,
                    skipped_counts=skipped_counts,
                    created_at=datetime.utcnow()
                )
            
            # Stop if there are validation errors
            if validation_errors:
                return ImportResponse(
                    import_id=import_id,
                    status="failed",
                    validation_errors=validation_errors,
                    imported_counts=imported_counts,
                    skipped_counts=skipped_counts,
                    created_at=datetime.utcnow()
                )
            
            # Import activities
            if import_request.import_activities and "activities" in import_data:
                for activity_data in import_data["activities"]:
                    try:
                        # Check if activity already exists
                        existing_activity = await self.db.execute(
                            select(Activity).where(Activity.id == activity_data["id"])
                        )
                        existing = existing_activity.scalar_one_or_none()
                        
                        if existing and not import_request.overwrite_existing:
                            skipped_counts["activities"] += 1
                            continue
                        
                        # Create or update activity
                        if existing and import_request.overwrite_existing:
                            # Update existing activity
                            for key, value in activity_data.items():
                                if key != "id" and hasattr(existing, key):
                                    setattr(existing, key, value)
                        else:
                            # Create new activity
                            activity = Activity(
                                id=uuid.UUID(activity_data["id"]),
                                user_id=user_id,
                                title=activity_data["title"],
                                description=activity_data.get("description"),
                                category=activity_data["category"],
                                tags=activity_data.get("tags", []),
                                impact_level=activity_data.get("impact_level"),
                                date=datetime.fromisoformat(activity_data["date"]).date() if isinstance(activity_data["date"], str) else activity_data["date"],
                                duration_minutes=activity_data.get("duration_minutes"),
                                metadata_json=activity_data.get("metadata", {}),
                                created_at=datetime.fromisoformat(activity_data["created_at"]) if isinstance(activity_data["created_at"], str) else activity_data["created_at"],
                                updated_at=datetime.fromisoformat(activity_data["updated_at"]) if isinstance(activity_data["updated_at"], str) else activity_data["updated_at"],
                            )
                            self.db.add(activity)
                        
                        imported_counts["activities"] += 1
                        
                    except Exception as e:
                        validation_errors.append(f"Failed to import activity {activity_data.get('id', 'unknown')}: {str(e)}")
            
            # Import stories
            if import_request.import_stories and "stories" in import_data:
                for story_data in import_data["stories"]:
                    try:
                        # Check if story already exists
                        existing_story = await self.db.execute(
                            select(Story).where(Story.id == story_data["id"])
                        )
                        existing = existing_story.scalar_one_or_none()
                        
                        if existing and not import_request.overwrite_existing:
                            skipped_counts["stories"] += 1
                            continue
                        
                        # Create or update story
                        if existing and import_request.overwrite_existing:
                            # Update existing story
                            for key, value in story_data.items():
                                if key != "id" and hasattr(existing, key):
                                    setattr(existing, key, value)
                        else:
                            # Create new story
                            story = Story(
                                id=uuid.UUID(story_data["id"]),
                                user_id=user_id,
                                title=story_data["title"],
                                situation=story_data["situation"],
                                task=story_data["task"],
                                action=story_data["action"],
                                result=story_data["result"],
                                impact_metrics=story_data.get("impact_metrics", {}),
                                tags=story_data.get("tags", []),
                                status=story_data["status"],
                                ai_enhanced=story_data.get("ai_enhanced", False),
                                created_at=datetime.fromisoformat(story_data["created_at"]) if isinstance(story_data["created_at"], str) else story_data["created_at"],
                                updated_at=datetime.fromisoformat(story_data["updated_at"]) if isinstance(story_data["updated_at"], str) else story_data["updated_at"],
                            )
                            self.db.add(story)
                        
                        imported_counts["stories"] += 1
                        
                    except Exception as e:
                        validation_errors.append(f"Failed to import story {story_data.get('id', 'unknown')}: {str(e)}")
            
            # Import reports
            if import_request.import_reports and "reports" in import_data:
                for report_data in import_data["reports"]:
                    try:
                        # Check if report already exists
                        existing_report = await self.db.execute(
                            select(Report).where(Report.id == report_data["id"])
                        )
                        existing = existing_report.scalar_one_or_none()
                        
                        if existing and not import_request.overwrite_existing:
                            skipped_counts["reports"] += 1
                            continue
                        
                        # Create or update report
                        if existing and import_request.overwrite_existing:
                            # Update existing report
                            for key, value in report_data.items():
                                if key != "id" and hasattr(existing, key):
                                    setattr(existing, key, value)
                        else:
                            # Create new report
                            report = Report(
                                id=uuid.UUID(report_data["id"]),
                                user_id=user_id,
                                title=report_data["title"],
                                period_start=datetime.fromisoformat(report_data["period_start"]).date() if isinstance(report_data["period_start"], str) else report_data["period_start"],
                                period_end=datetime.fromisoformat(report_data["period_end"]).date() if isinstance(report_data["period_end"], str) else report_data["period_end"],
                                report_type=report_data["report_type"],
                                content=report_data.get("content"),
                                activities_included=report_data.get("activities_included", []),
                                stories_included=report_data.get("stories_included", []),
                                generated_by_ai=report_data.get("generated_by_ai", False),
                                status=report_data["status"],
                                created_at=datetime.fromisoformat(report_data["created_at"]) if isinstance(report_data["created_at"], str) else report_data["created_at"],
                                updated_at=datetime.fromisoformat(report_data["updated_at"]) if isinstance(report_data["updated_at"], str) else report_data["updated_at"],
                            )
                            self.db.add(report)
                        
                        imported_counts["reports"] += 1
                        
                    except Exception as e:
                        validation_errors.append(f"Failed to import report {report_data.get('id', 'unknown')}: {str(e)}")
            
            # Commit the transaction
            await self.db.commit()
            
            status = "complete" if not validation_errors else "partial"
            
            return ImportResponse(
                import_id=import_id,
                status=status,
                validation_errors=validation_errors,
                imported_counts=imported_counts,
                skipped_counts=skipped_counts,
                created_at=datetime.utcnow()
            )
            
        except Exception as e:
            await self.db.rollback()
            return ImportResponse(
                import_id=import_id,
                status="failed",
                validation_errors=[f"Import failed: {str(e)}"],
                imported_counts=imported_counts,
                skipped_counts=skipped_counts,
                created_at=datetime.utcnow()
            )
    
    async def create_backup(
        self,
        user_id: uuid.UUID,
        backup_request: BackupRequest
    ) -> BackupResponse:
        """
        Create an automated backup of user data.
        
        Args:
            user_id: User ID for the backup
            backup_request: Backup configuration
            
        Returns:
            BackupResponse with backup details
        """
        backup_id = str(uuid.uuid4())
        
        try:
            # Create a full export for backup
            export_request = ExportRequest(
                format=ExportFormat.JSON,
                include_activities=True,
                include_stories=True,
                include_reports=True,
                include_user_profile=backup_request.include_user_data
            )
            
            # Collect all user data
            export_data = await self._collect_export_data(user_id, export_request)
            
            # Generate backup file
            backup_content, file_size = await self._generate_json_export(export_data)
            
            # Store backup file (in production, this would be S3 with lifecycle policies)
            backup_path = await self._store_backup_file(
                backup_id, 
                backup_content, 
                backup_request.backup_type,
                user_id
            )
            
            # Calculate expiration based on retention policy
            expires_at = datetime.utcnow() + timedelta(days=backup_request.retention_days)
            
            return BackupResponse(
                backup_id=backup_id,
                backup_type=backup_request.backup_type,
                status="complete",
                file_path=backup_path,
                file_size_bytes=file_size,
                created_at=datetime.utcnow(),
                expires_at=expires_at
            )
            
        except Exception as e:
            return BackupResponse(
                backup_id=backup_id,
                backup_type=backup_request.backup_type,
                status="failed",
                file_path="",
                file_size_bytes=0,
                created_at=datetime.utcnow(),
                expires_at=datetime.utcnow()
            )
    
    async def _store_backup_file(
        self,
        backup_id: str,
        backup_content: bytes,
        backup_type: str,
        user_id: uuid.UUID
    ) -> str:
        """
        Store backup file.
        In production, this would upload to S3 with appropriate lifecycle policies.
        """
        # In production: upload to S3 with backup lifecycle policies
        # For now, return a simulated path
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        backup_path = f"/backups/{backup_type}/{user_id}/{timestamp}_{backup_id}.json"
        
        # In a real implementation, we would:
        # s3_client.put_object(
        #     Bucket=backup_bucket, 
        #     Key=backup_path, 
        #     Body=backup_content,
        #     StorageClass='STANDARD_IA',  # For cost optimization
        #     Lifecycle configuration for automatic deletion
        # )
        
        return backup_path
