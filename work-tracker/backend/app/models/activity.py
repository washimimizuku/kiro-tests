"""
Activity Model

SQLAlchemy model for professional activity tracking.
"""

from sqlalchemy import Column, String, Text, Integer, Date, JSON, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
import uuid
from enum import Enum

from app.core.database import Base, TimestampMixin


class ActivityCategory(str, Enum):
    """Enumeration of activity categories."""
    CUSTOMER_ENGAGEMENT = "customer_engagement"
    LEARNING = "learning"
    SPEAKING = "speaking"
    MENTORING = "mentoring"
    TECHNICAL_CONSULTATION = "technical_consultation"
    CONTENT_CREATION = "content_creation"


class Activity(Base, TimestampMixin):
    """Activity model for tracking professional work items."""
    
    __tablename__ = "activities"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(Text)
    category = Column(String(50), nullable=False)
    tags = Column(ARRAY(String), default=list)
    impact_level = Column(Integer, CheckConstraint("impact_level >= 1 AND impact_level <= 5"))
    date = Column(Date, nullable=False, index=True)
    duration_minutes = Column(Integer)
    metadata = Column(JSON, default=dict)
    
    # Relationships
    user = relationship("User", back_populates="activities")
    
    # Constraints
    __table_args__ = (
        CheckConstraint(
            "category IN ('customer_engagement', 'learning', 'speaking', 'mentoring', 'technical_consultation', 'content_creation')",
            name="check_activity_category"
        ),
    )
    
    def __repr__(self) -> str:
        return f"<Activity(id={self.id}, title='{self.title}', category='{self.category}')>"