"""
Story Model

SQLAlchemy model for customer success stories in STAR format.
"""

from sqlalchemy import Column, String, Text, Boolean, JSON, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
import uuid
from enum import Enum

from app.core.database import Base, TimestampMixin


class StoryStatus(str, Enum):
    """Enumeration of story statuses."""
    DRAFT = "draft"
    COMPLETE = "complete"
    PUBLISHED = "published"


class Story(Base, TimestampMixin):
    """Story model for STAR format customer success stories."""
    
    __tablename__ = "stories"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(500), nullable=False)
    
    # STAR format fields
    situation = Column(Text, nullable=False)
    task = Column(Text, nullable=False)
    action = Column(Text, nullable=False)
    result = Column(Text, nullable=False)
    
    impact_metrics = Column(JSON, default=dict)
    tags = Column(ARRAY(String), default=list)
    status = Column(String(20), default=StoryStatus.DRAFT.value)
    ai_enhanced = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="stories")
    
    # Constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'complete', 'published')",
            name="check_story_status"
        ),
    )
    
    def __repr__(self) -> str:
        return f"<Story(id={self.id}, title='{self.title}', status='{self.status}')>"