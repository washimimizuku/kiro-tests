"""
Pydantic schemas for AI service requests and responses.
"""
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from datetime import date


class StoryEnhancementRequest(BaseModel):
    """Request schema for story enhancement."""
    situation: str = Field(..., description="Situation section of the STAR story")
    task: str = Field(..., description="Task section of the STAR story")
    action: str = Field(..., description="Action section of the STAR story")
    result: str = Field(..., description="Result section of the STAR story")


class StoryEnhancementSuggestion(BaseModel):
    """Individual enhancement suggestion."""
    section: str = Field(..., description="STAR section this suggestion applies to")
    suggestion: str = Field(..., description="The enhancement suggestion")
    priority: int = Field(..., ge=1, le=5, description="Priority level (1-5)")


class StoryEnhancementResponse(BaseModel):
    """Response schema for story enhancement."""
    situation_suggestions: List[str] = Field(default_factory=list)
    task_suggestions: List[str] = Field(default_factory=list)
    action_suggestions: List[str] = Field(default_factory=list)
    result_suggestions: List[str] = Field(default_factory=list)
    overall_suggestions: List[str] = Field(default_factory=list)
    impact_score: int = Field(..., ge=1, le=10, description="Impact score (1-10)")
    completeness_score: int = Field(..., ge=1, le=10, description="Completeness score (1-10)")


class StoryCompletenessRequest(BaseModel):
    """Request schema for story completeness analysis."""
    situation: Optional[str] = Field(None, description="Situation section")
    task: Optional[str] = Field(None, description="Task section")
    action: Optional[str] = Field(None, description="Action section")
    result: Optional[str] = Field(None, description="Result section")


class StoryCompletenessResponse(BaseModel):
    """Response schema for story completeness analysis."""
    situation_complete: bool
    situation_missing: List[str] = Field(default_factory=list)
    task_complete: bool
    task_missing: List[str] = Field(default_factory=list)
    action_complete: bool
    action_missing: List[str] = Field(default_factory=list)
    result_complete: bool
    result_missing: List[str] = Field(default_factory=list)
    completeness_percentage: int = Field(..., ge=0, le=100)
    priority_improvements: List[str] = Field(default_factory=list)


class ImpactMetric(BaseModel):
    """Individual impact metric suggestion."""
    metric_name: str = Field(..., description="Name of the metric")
    description: str = Field(..., description="Description of what this metric measures")
    example_value: str = Field(..., description="Example value for this metric")


class ImpactQuantificationRequest(BaseModel):
    """Request schema for impact quantification."""
    story_content: str = Field(..., description="Full story content to analyze")


class ImpactQuantificationResponse(BaseModel):
    """Response schema for impact quantification."""
    suggested_metrics: List[ImpactMetric] = Field(default_factory=list)
    quantification_opportunities: List[str] = Field(default_factory=list)
    impact_categories: List[str] = Field(default_factory=list)


class ActivitySummary(BaseModel):
    """Summary of an activity for report generation."""
    title: str
    category: str
    date: date
    description: str
    impact_level: int = Field(..., ge=1, le=5)
    tags: List[str] = Field(default_factory=list)
    duration_minutes: Optional[int] = None


class ReportGenerationRequest(BaseModel):
    """Request schema for report generation."""
    activities: List[ActivitySummary] = Field(..., description="Activities to include in report")
    period_start: date = Field(..., description="Start date of reporting period")
    period_end: date = Field(..., description="End date of reporting period")
    report_type: str = Field(..., description="Type of report (weekly, monthly, quarterly, annual)")
    custom_instructions: Optional[str] = Field(None, description="Custom instructions for report generation")


class ReportGenerationResponse(BaseModel):
    """Response schema for report generation."""
    report_content: str = Field(..., description="Generated report content in Markdown format")
    executive_summary: str = Field(..., description="Executive summary of the report")
    key_achievements: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    word_count: int = Field(..., description="Word count of the generated report")


class ActivityAnalysisRequest(BaseModel):
    """Request schema for activity analysis."""
    activities: List[ActivitySummary] = Field(..., description="Activities to analyze")


class ActivityAnalysisResponse(BaseModel):
    """Response schema for activity analysis."""
    category_distribution: Dict[str, float] = Field(default_factory=dict)
    high_impact_themes: List[str] = Field(default_factory=list)
    skills_demonstrated: List[str] = Field(default_factory=list)
    growth_areas: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)


class CalendarEventSuggestionRequest(BaseModel):
    """Request schema for calendar event activity suggestion."""
    event_title: str = Field(..., description="Title of the calendar event")
    event_description: Optional[str] = Field(None, description="Description of the event")
    attendees: List[str] = Field(default_factory=list, description="List of attendee names/emails")
    duration_minutes: int = Field(..., gt=0, description="Duration of the event in minutes")


class CalendarEventSuggestionResponse(BaseModel):
    """Response schema for calendar event activity suggestion."""
    suggested_category: str = Field(..., description="Suggested activity category")
    suggested_title: str = Field(..., description="Suggested activity title")
    suggested_description: str = Field(..., description="Suggested activity description")
    suggested_impact_level: int = Field(..., ge=1, le=5, description="Suggested impact level")
    suggested_tags: List[str] = Field(default_factory=list, description="Suggested tags")
    confidence: int = Field(..., ge=0, le=100, description="Confidence in the suggestion")


class AIHealthCheckResponse(BaseModel):
    """Response schema for AI service health check."""
    status: str = Field(..., description="Health status (healthy/unhealthy)")
    bedrock_available: bool = Field(..., description="Whether Bedrock service is available")
    response_time_ms: Optional[float] = Field(None, description="Response time in milliseconds")
    error_message: Optional[str] = Field(None, description="Error message if unhealthy")