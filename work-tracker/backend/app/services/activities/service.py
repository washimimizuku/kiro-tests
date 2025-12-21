"""
Activity Service

Business logic for activity management including CRUD operations,
validation, categorization, and tag management.
"""

from typing import List, Optional, Dict, Any
from uuid import UUID
from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
from sqlalchemy.orm import selectinload

from app.models.activity import Activity, ActivityCategory
from app.schemas.activity import ActivityCreate, ActivityUpdate, ActivityFilters
from app.core.exceptions import NotFoundError, ValidationError


class ActivityService:
    """Service class for activity management operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_activity(self, user_id: UUID, activity_data: ActivityCreate) -> Activity:
        """
        Create a new activity for the specified user.
        
        Args:
            user_id: UUID of the user creating the activity
            activity_data: Activity creation data
            
        Returns:
            Created Activity instance
            
        Raises:
            ValidationError: If activity data is invalid
        """
        # Validate category
        if activity_data.category not in ActivityCategory:
            raise ValidationError(f"Invalid category: {activity_data.category}")
        
        # Create activity instance
        activity = Activity(
            user_id=user_id,
            title=activity_data.title.strip(),
            description=activity_data.description.strip() if activity_data.description else None,
            category=activity_data.category.value,
            tags=list(set(tag.strip().lower() for tag in activity_data.tags if tag.strip())),  # Normalize tags
            impact_level=activity_data.impact_level,
            date=activity_data.date,
            duration_minutes=activity_data.duration_minutes,
            metadata_json=activity_data.metadata or {}
        )
        
        # Save to database
        self.db.add(activity)
        await self.db.commit()
        await self.db.refresh(activity)
        
        return activity
    
    async def get_activity(self, user_id: UUID, activity_id: UUID) -> Activity:
        """
        Get a specific activity by ID for the specified user.
        
        Args:
            user_id: UUID of the user
            activity_id: UUID of the activity
            
        Returns:
            Activity instance
            
        Raises:
            NotFoundError: If activity is not found or doesn't belong to user
        """
        query = select(Activity).where(
            and_(Activity.id == activity_id, Activity.user_id == user_id)
        )
        result = await self.db.execute(query)
        activity = result.scalar_one_or_none()
        
        if not activity:
            raise NotFoundError(f"Activity {activity_id} not found")
        
        return activity
    
    async def list_activities(self, user_id: UUID, filters: ActivityFilters) -> List[Activity]:
        """
        List activities for the specified user with optional filtering.
        
        Args:
            user_id: UUID of the user
            filters: Filtering parameters
            
        Returns:
            List of Activity instances
        """
        query = select(Activity).where(Activity.user_id == user_id)
        
        # Apply filters
        if filters.category:
            query = query.where(Activity.category == filters.category.value)
        
        if filters.tags:
            # Activities must have at least one of the specified tags
            tag_conditions = [Activity.tags.contains([tag]) for tag in filters.tags]
            query = query.where(or_(*tag_conditions))
        
        if filters.date_from:
            query = query.where(Activity.date >= filters.date_from)
        
        if filters.date_to:
            query = query.where(Activity.date <= filters.date_to)
        
        if filters.impact_level_min:
            query = query.where(Activity.impact_level >= filters.impact_level_min)
        
        if filters.impact_level_max:
            query = query.where(Activity.impact_level <= filters.impact_level_max)
        
        if filters.search:
            search_term = f"%{filters.search.lower()}%"
            query = query.where(
                or_(
                    func.lower(Activity.title).like(search_term),
                    func.lower(Activity.description).like(search_term)
                )
            )
        
        # Order by date descending, then by creation time
        query = query.order_by(desc(Activity.date), desc(Activity.created_at))
        
        # Apply pagination
        query = query.offset(filters.offset).limit(filters.limit)
        
        result = await self.db.execute(query)
        return result.scalars().all()
    
    async def update_activity(self, user_id: UUID, activity_id: UUID, update_data: ActivityUpdate) -> Activity:
        """
        Update an existing activity.
        
        Args:
            user_id: UUID of the user
            activity_id: UUID of the activity to update
            update_data: Activity update data
            
        Returns:
            Updated Activity instance
            
        Raises:
            NotFoundError: If activity is not found or doesn't belong to user
            ValidationError: If update data is invalid
        """
        # Get existing activity
        activity = await self.get_activity(user_id, activity_id)
        
        # Update fields if provided
        update_dict = update_data.model_dump(exclude_unset=True)
        
        for field, value in update_dict.items():
            if field == "category" and value:
                if value not in ActivityCategory:
                    raise ValidationError(f"Invalid category: {value}")
                setattr(activity, field, value.value)
            elif field == "title" and value:
                setattr(activity, field, value.strip())
            elif field == "description" and value is not None:
                setattr(activity, field, value.strip() if value else None)
            elif field == "tags" and value is not None:
                # Normalize tags
                setattr(activity, field, list(set(tag.strip().lower() for tag in value if tag.strip())))
            else:
                setattr(activity, field, value)
        
        await self.db.commit()
        await self.db.refresh(activity)
        
        return activity
    
    async def delete_activity(self, user_id: UUID, activity_id: UUID) -> None:
        """
        Delete an activity.
        
        Args:
            user_id: UUID of the user
            activity_id: UUID of the activity to delete
            
        Raises:
            NotFoundError: If activity is not found or doesn't belong to user
        """
        activity = await self.get_activity(user_id, activity_id)
        await self.db.delete(activity)
        await self.db.commit()
    
    async def get_activity_tags(self, user_id: UUID) -> List[str]:
        """
        Get all unique tags used by the user's activities.
        
        Args:
            user_id: UUID of the user
            
        Returns:
            List of unique tags
        """
        query = select(Activity.tags).where(Activity.user_id == user_id)
        result = await self.db.execute(query)
        
        # Flatten and deduplicate tags
        all_tags = set()
        for tag_list in result.scalars():
            if tag_list:
                all_tags.update(tag_list)
        
        return sorted(list(all_tags))
    
    async def get_tag_suggestions(self, user_id: UUID, partial_tag: str, limit: int = 10) -> List[str]:
        """
        Get tag suggestions based on partial input.
        
        Args:
            user_id: UUID of the user
            partial_tag: Partial tag to match against
            limit: Maximum number of suggestions to return
            
        Returns:
            List of matching tags
        """
        user_tags = await self.get_activity_tags(user_id)
        partial_lower = partial_tag.lower().strip()
        
        # Find tags that start with or contain the partial tag
        matching_tags = [
            tag for tag in user_tags 
            if partial_lower in tag.lower()
        ]
        
        # Sort by relevance (starts with first, then contains)
        starts_with = [tag for tag in matching_tags if tag.lower().startswith(partial_lower)]
        contains = [tag for tag in matching_tags if not tag.lower().startswith(partial_lower)]
        
        return (starts_with + contains)[:limit]
    
    async def get_activity_count(self, user_id: UUID, filters: Optional[ActivityFilters] = None) -> int:
        """
        Get the total count of activities for a user with optional filtering.
        
        Args:
            user_id: UUID of the user
            filters: Optional filtering parameters
            
        Returns:
            Total count of matching activities
        """
        query = select(func.count(Activity.id)).where(Activity.user_id == user_id)
        
        if filters:
            if filters.category:
                query = query.where(Activity.category == filters.category.value)
            
            if filters.tags:
                tag_conditions = [Activity.tags.contains([tag]) for tag in filters.tags]
                query = query.where(or_(*tag_conditions))
            
            if filters.date_from:
                query = query.where(Activity.date >= filters.date_from)
            
            if filters.date_to:
                query = query.where(Activity.date <= filters.date_to)
            
            if filters.impact_level_min:
                query = query.where(Activity.impact_level >= filters.impact_level_min)
            
            if filters.impact_level_max:
                query = query.where(Activity.impact_level <= filters.impact_level_max)
            
            if filters.search:
                search_term = f"%{filters.search.lower()}%"
                query = query.where(
                    or_(
                        func.lower(Activity.title).like(search_term),
                        func.lower(Activity.description).like(search_term)
                    )
                )
        
        result = await self.db.execute(query)
        return result.scalar()
    
    async def get_activity_title_suggestions(self, user_id: UUID, partial_title: str, limit: int = 10) -> List[str]:
        """
        Get activity title suggestions based on partial input.
        
        Args:
            user_id: UUID of the user
            partial_title: Partial title to match against
            limit: Maximum number of suggestions to return
            
        Returns:
            List of matching activity titles
        """
        partial_lower = partial_title.lower().strip()
        if not partial_lower:
            return []
        
        # Query for activities with titles that contain the partial title
        search_term = f"%{partial_lower}%"
        query = select(Activity.title).where(
            and_(
                Activity.user_id == user_id,
                func.lower(Activity.title).like(search_term)
            )
        ).distinct().order_by(Activity.title).limit(limit)
        
        result = await self.db.execute(query)
        titles = result.scalars().all()
        
        # Sort by relevance (starts with first, then contains)
        starts_with = [title for title in titles if title.lower().startswith(partial_lower)]
        contains = [title for title in titles if not title.lower().startswith(partial_lower)]
        
        return (starts_with + contains)[:limit]