"""
Report Model

SQLAlchemy model for generated reports.
"""

from sqlalchemy import Column, String, Text, Date, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
import uuid
from enum import Enum

from app.core.database import Base, TimestampMixin


class ReportType(str, Enum):
    """Enumeration of report types."""
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    ANNUAL = "annual"
    CUSTOM = "custom"


class ReportStatus(str, Enum):
    """Enumeration of report statuses."""
    DRAFT = "draft"
    GENERATING = "generating"
    COMPLETE = "complete"
    FAILED = "failed"


class Report(Base, TimestampMixin):
    """Report model for generated activity summaries."""
    
    __tablename__ = "reports"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(500), nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    report_type = Column(String(20), nullable=False)
    content = Column(Text)
    activities_included = Column(ARRAY(UUID), default=list)
    stories_included = Column(ARRAY(UUID), default=list)
    generated_by_ai = Column(Boolean, default=False)
    status = Column(String(20), default=ReportStatus.DRAFT.value)
    
    # Relationships
    user = relationship("User", back_populates="reports")
    
    # Constraints
    __table_args__ = (
        CheckConstraint(
            "report_type IN ('weekly', 'monthly', 'quarterly', 'annual', 'custom')",
            name="check_report_type"
        ),
        CheckConstraint(
            "status IN ('draft', 'generating', 'complete', 'failed')",
            name="check_report_status"
        ),
    )
    
    def __repr__(self) -> str:
        return f"<Report(id={self.id}, title='{self.title}', type='{self.report_type}')>"