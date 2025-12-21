"""
Story Service

Business logic for story management including CRUD operations,
STAR format validation, and story search/filtering.
"""

from typing import List, Optional, Dict, Any
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from datetime import datetime

from app.models.story import Story, StoryStatus
from app.schemas.story import (
    StoryCreate, StoryUpdate, StoryResponse, StorySummary, 
    StoryFilters, StoryEnhancementRequest
)
from app.core.database import get_db


class StoryService:
    """Service class for story management operations."""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def create_story(self, user_id: UUID, story_data: StoryCreate) -> Story:
        """Create a new story with STAR format validation."""
        # Validate STAR format completeness
        star_completeness = self._validate_star_format(story_data)
        
        # Determine initial status based on completeness
        if star_completeness >= 0.8 and story_data.status and story_data.status != StoryStatus.DRAFT:
            status = story_data.status
        else:
            status = StoryStatus.DRAFT
        
        story = Story(
            user_id=user_id,
            title=story_data.title,
            situation=story_data.situation,
            task=story_data.task,
            action=story_data.action,
            result=story_data.result,
            impact_metrics=story_data.impact_metrics,
            tags=story_data.tags,
            status=status.value
        )
        
        self.db.add(story)
        self.db.commit()
        self.db.refresh(story)
        
        return story
    
    async def get_story(self, user_id: UUID, story_id: UUID) -> Optional[Story]:
        """Retrieve a specific story by ID."""
        return self.db.query(Story).filter(
            and_(Story.id == story_id, Story.user_id == user_id)
        ).first()
    
    async def list_stories(self, user_id: UUID, filters: StoryFilters) -> List[Story]:
        """List stories with filtering and pagination."""
        query = self.db.query(Story).filter(Story.user_id == user_id)
        
        # Apply filters
        if filters.status:
            query = query.filter(Story.status == filters.status.value)
        
        if filters.tags:
            # Filter stories that contain any of the specified tags
            query = query.filter(Story.tags.overlap(filters.tags))
        
        if filters.ai_enhanced is not None:
            query = query.filter(Story.ai_enhanced == filters.ai_enhanced)
        
        if filters.search:
            # Search in title, situation, task, action, and result
            search_term = f"%{filters.search}%"
            query = query.filter(
                or_(
                    Story.title.ilike(search_term),
                    Story.situation.ilike(search_term),
                    Story.task.ilike(search_term),
                    Story.action.ilike(search_term),
                    Story.result.ilike(search_term)
                )
            )
        
        # Apply pagination and ordering
        query = query.order_by(Story.updated_at.desc())
        query = query.offset(filters.offset).limit(filters.limit)
        
        return query.all()
    
    async def update_story(self, user_id: UUID, story_id: UUID, story_data: StoryUpdate) -> Optional[Story]:
        """Update an existing story."""
        story = await self.get_story(user_id, story_id)
        if not story:
            return None
        
        # Update fields if provided
        update_data = story_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(story, field, value)
        
        # Re-validate STAR format if content changed
        if any(field in update_data for field in ['situation', 'task', 'action', 'result']):
            star_completeness = self._validate_star_format_from_story(story)
            
            # Auto-promote to complete if STAR format is sufficiently complete
            if star_completeness >= 0.8 and story.status == StoryStatus.DRAFT.value:
                story.status = StoryStatus.COMPLETE.value
        
        story.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(story)
        
        return story
    
    async def delete_story(self, user_id: UUID, story_id: UUID) -> bool:
        """Delete a story."""
        story = await self.get_story(user_id, story_id)
        if not story:
            return False
        
        self.db.delete(story)
        self.db.commit()
        return True
    
    async def get_story_summaries(self, user_id: UUID, limit: int = 10) -> List[StorySummary]:
        """Get recent story summaries for dashboard display."""
        stories = self.db.query(Story).filter(
            Story.user_id == user_id
        ).order_by(Story.updated_at.desc()).limit(limit).all()
        
        return [
            StorySummary(
                id=story.id,
                title=story.title,
                status=StoryStatus(story.status),
                ai_enhanced=story.ai_enhanced,
                created_at=story.created_at
            )
            for story in stories
        ]
    
    async def get_story_tags(self, user_id: UUID) -> List[str]:
        """Get all unique tags used by the user's stories."""
        result = self.db.query(func.unnest(Story.tags).label('tag')).filter(
            Story.user_id == user_id
        ).distinct().all()
        
        return [row.tag for row in result if row.tag]
    
    async def update_story_status(self, user_id: UUID, story_id: UUID, status: StoryStatus) -> Optional[Story]:
        """Update story status with validation."""
        story = await self.get_story(user_id, story_id)
        if not story:
            return None
        
        # Validate status transition
        if status == StoryStatus.COMPLETE:
            star_completeness = self._validate_star_format_from_story(story)
            if star_completeness < 0.8:
                raise ValueError("Story must be at least 80% complete to mark as complete")
        
        story.status = status.value
        story.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(story)
        
        return story
    
    def _validate_star_format(self, story_data: StoryCreate) -> float:
        """Validate STAR format completeness and return score (0.0-1.2)."""
        fields = [story_data.situation, story_data.task, story_data.action, story_data.result]
        
        # Check if all fields are present and non-empty
        non_empty_fields = sum(1 for field in fields if field and field.strip())
        
        # Basic completeness score
        completeness = non_empty_fields / 4.0
        
        # Bonus for meaningful content (more than just a few words)
        meaningful_fields = sum(1 for field in fields if field and len(field.strip()) > 20)
        completeness += (meaningful_fields / 4.0) * 0.2
        
        return completeness  # Allow scores > 1.0 for bonus content
    
    def _validate_star_format_from_story(self, story: Story) -> float:
        """Validate STAR format completeness from existing story."""
        fields = [story.situation, story.task, story.action, story.result]
        
        # Check if all fields are present and non-empty
        non_empty_fields = sum(1 for field in fields if field and field.strip())
        
        # Basic completeness score
        completeness = non_empty_fields / 4.0
        
        # Bonus for meaningful content (more than just a few words)
        meaningful_fields = sum(1 for field in fields if field and len(field.strip()) > 20)
        completeness += (meaningful_fields / 4.0) * 0.2
        
        return completeness  # Allow scores > 1.0 for bonus content
    
    async def search_stories(self, user_id: UUID, query: str, limit: int = 20) -> List[Story]:
        """Advanced search functionality for stories."""
        search_term = f"%{query}%"
        
        stories = self.db.query(Story).filter(
            and_(
                Story.user_id == user_id,
                or_(
                    Story.title.ilike(search_term),
                    Story.situation.ilike(search_term),
                    Story.task.ilike(search_term),
                    Story.action.ilike(search_term),
                    Story.result.ilike(search_term),
                    Story.tags.any(func.lower(func.unnest(Story.tags)).like(query.lower()))
                )
            )
        ).order_by(Story.updated_at.desc()).limit(limit).all()
        
        return stories
    
    async def get_story_categories(self, user_id: UUID) -> Dict[str, int]:
        """Get story categories with counts for the user."""
        # Extract categories from impact_metrics
        categories = {}
        stories = self.db.query(Story).filter(Story.user_id == user_id).all()
        
        for story in stories:
            if story.impact_metrics and 'category' in story.impact_metrics:
                category = story.impact_metrics['category']
                categories[category] = categories.get(category, 0) + 1
            else:
                categories['uncategorized'] = categories.get('uncategorized', 0) + 1
        
        return categories
    
    async def update_story_impact_metrics(self, user_id: UUID, story_id: UUID, metrics: Dict[str, Any]) -> Optional[Story]:
        """Update story impact metrics."""
        story = await self.get_story(user_id, story_id)
        if not story:
            return None
        
        # Merge new metrics with existing ones
        current_metrics = story.impact_metrics or {}
        current_metrics.update(metrics)
        story.impact_metrics = current_metrics
        
        story.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(story)
        
        return story
    
    async def get_story_templates(self) -> List[Dict[str, Any]]:
        """Get predefined story templates for different scenarios."""
        templates = [
            {
                "name": "Customer Success Story",
                "description": "Template for documenting customer success and impact",
                "category": "customer_success",
                "template": {
                    "situation": "Describe the customer's initial challenge or situation...",
                    "task": "Explain what needed to be accomplished or solved...",
                    "action": "Detail the specific actions you took to address the situation...",
                    "result": "Quantify the outcomes and impact achieved..."
                },
                "impact_metrics_template": {
                    "category": "customer_success",
                    "customer_satisfaction": "",
                    "revenue_impact": "",
                    "time_saved": "",
                    "efficiency_gain": ""
                }
            },
            {
                "name": "Technical Innovation",
                "description": "Template for technical achievements and innovations",
                "category": "technical",
                "template": {
                    "situation": "Describe the technical challenge or opportunity...",
                    "task": "Explain the technical requirements or goals...",
                    "action": "Detail the technical solution and implementation...",
                    "result": "Quantify the technical improvements and benefits..."
                },
                "impact_metrics_template": {
                    "category": "technical",
                    "performance_improvement": "",
                    "cost_reduction": "",
                    "scalability_gain": "",
                    "reliability_improvement": ""
                }
            },
            {
                "name": "Team Leadership",
                "description": "Template for leadership and team development stories",
                "category": "leadership",
                "template": {
                    "situation": "Describe the team or organizational challenge...",
                    "task": "Explain the leadership objectives or team goals...",
                    "action": "Detail your leadership actions and strategies...",
                    "result": "Quantify the team improvements and outcomes..."
                },
                "impact_metrics_template": {
                    "category": "leadership",
                    "team_productivity": "",
                    "employee_satisfaction": "",
                    "retention_improvement": "",
                    "skill_development": ""
                }
            },
            {
                "name": "Process Improvement",
                "description": "Template for process optimization and efficiency gains",
                "category": "process",
                "template": {
                    "situation": "Describe the inefficient process or workflow...",
                    "task": "Explain what needed to be optimized or improved...",
                    "action": "Detail the process changes and improvements made...",
                    "result": "Quantify the efficiency gains and cost savings..."
                },
                "impact_metrics_template": {
                    "category": "process",
                    "time_savings": "",
                    "cost_reduction": "",
                    "error_reduction": "",
                    "automation_level": ""
                }
            }
        ]
        
        return templates
    
    async def get_story_guidance(self, story_id: UUID, user_id: UUID) -> Dict[str, Any]:
        """Get guidance and suggestions for improving a story."""
        story = await self.get_story(user_id, story_id)
        if not story:
            return {}
        
        guidance = {
            "completeness_score": self._validate_star_format_from_story(story),
            "suggestions": [],
            "missing_elements": [],
            "impact_metrics_suggestions": []
        }
        
        # Check STAR format completeness
        if not story.situation or len(story.situation.strip()) < 20:
            guidance["missing_elements"].append("situation")
            guidance["suggestions"].append("Expand the Situation section with more context about the initial challenge or opportunity")
        
        if not story.task or len(story.task.strip()) < 20:
            guidance["missing_elements"].append("task")
            guidance["suggestions"].append("Clarify the Task section with specific objectives and requirements")
        
        if not story.action or len(story.action.strip()) < 20:
            guidance["missing_elements"].append("action")
            guidance["suggestions"].append("Detail the Action section with specific steps and methodologies used")
        
        if not story.result or len(story.result.strip()) < 20:
            guidance["missing_elements"].append("result")
            guidance["suggestions"].append("Quantify the Result section with measurable outcomes and impact")
        
        # Check impact metrics
        if not story.impact_metrics or len(story.impact_metrics) == 0:
            guidance["impact_metrics_suggestions"].append("Add quantifiable impact metrics to strengthen your story")
        
        # Category-specific suggestions
        category = story.impact_metrics.get('category') if story.impact_metrics else None
        if category == "customer_success":
            guidance["impact_metrics_suggestions"].extend([
                "Include customer satisfaction scores or feedback",
                "Quantify revenue impact or business value",
                "Measure time savings or efficiency gains"
            ])
        elif category == "technical":
            guidance["impact_metrics_suggestions"].extend([
                "Include performance improvement percentages",
                "Quantify cost reductions or resource savings",
                "Measure scalability or reliability improvements"
            ])
        elif category == "leadership":
            guidance["impact_metrics_suggestions"].extend([
                "Include team productivity metrics",
                "Measure employee satisfaction or engagement",
                "Quantify retention or skill development outcomes"
            ])
        
        return guidance
    
    async def bulk_update_story_tags(self, user_id: UUID, old_tag: str, new_tag: str) -> int:
        """Bulk update story tags (rename or merge tags)."""
        stories = self.db.query(Story).filter(
            and_(Story.user_id == user_id, Story.tags.any(old_tag))
        ).all()
        
        updated_count = 0
        for story in stories:
            if old_tag in story.tags:
                # Replace old tag with new tag
                story.tags = [new_tag if tag == old_tag else tag for tag in story.tags]
                # Remove duplicates while preserving order
                story.tags = list(dict.fromkeys(story.tags))
                story.updated_at = datetime.utcnow()
                updated_count += 1
        
        self.db.commit()
        return updated_count
    
    async def delete_story_tag(self, user_id: UUID, tag_to_delete: str) -> int:
        """Remove a tag from all user stories."""
        stories = self.db.query(Story).filter(
            and_(Story.user_id == user_id, Story.tags.any(tag_to_delete))
        ).all()
        
        updated_count = 0
        for story in stories:
            if tag_to_delete in story.tags:
                story.tags = [tag for tag in story.tags if tag != tag_to_delete]
                story.updated_at = datetime.utcnow()
                updated_count += 1
        
        self.db.commit()
        return updated_count