"""
AI Service implementation for story enhancement and report generation.
"""
import json
import logging
from typing import List, Dict, Any, Optional
import time
from datetime import date

from .bedrock_client import get_bedrock_client, BedrockClientError
from .prompts import PromptTemplates
from .schemas import (
    StoryEnhancementRequest, StoryEnhancementResponse,
    StoryCompletenessRequest, StoryCompletenessResponse,
    ImpactQuantificationRequest, ImpactQuantificationResponse,
    ReportGenerationRequest, ReportGenerationResponse,
    ActivityAnalysisRequest, ActivityAnalysisResponse,
    CalendarEventSuggestionRequest, CalendarEventSuggestionResponse,
    AIHealthCheckResponse, ActivitySummary, ImpactMetric
)

logger = logging.getLogger(__name__)


class AIServiceError(Exception):
    """Custom exception for AI service errors."""
    pass


class AIService:
    """AI service for story enhancement and report generation using AWS Bedrock."""
    
    def __init__(self):
        """Initialize AI service."""
        self.bedrock_client = get_bedrock_client()
        self.prompt_templates = PromptTemplates()
    
    async def enhance_story(self, request: StoryEnhancementRequest) -> StoryEnhancementResponse:
        """
        Enhance a story using AI suggestions.
        
        Args:
            request: Story enhancement request with STAR format content
            
        Returns:
            Enhancement suggestions and scores
            
        Raises:
            AIServiceError: If enhancement fails
        """
        try:
            prompt = self.prompt_templates.story_enhancement_prompt(
                situation=request.situation,
                task=request.task,
                action=request.action,
                result=request.result
            )
            
            system_prompt = (
                "You are an expert career coach specializing in helping professionals "
                "write compelling success stories for performance reviews and career advancement. "
                "Always respond with valid JSON format."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.3  # Lower temperature for more consistent JSON output
            )
            
            # Parse JSON response
            try:
                response_data = json.loads(response)
                return StoryEnhancementResponse(**response_data)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse story enhancement response: {e}")
                # Return a fallback response
                return StoryEnhancementResponse(
                    situation_suggestions=["Consider adding more specific context and background"],
                    task_suggestions=["Clarify your specific role and responsibilities"],
                    action_suggestions=["Detail the specific steps you took"],
                    result_suggestions=["Quantify the outcomes and impact"],
                    overall_suggestions=["Add more specific metrics and measurable outcomes"],
                    impact_score=5,
                    completeness_score=5
                )
                
        except BedrockClientError as e:
            logger.error(f"Bedrock error in story enhancement: {e}")
            raise AIServiceError(f"Story enhancement failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in story enhancement: {e}")
            raise AIServiceError(f"Story enhancement failed: {e}")
    
    async def analyze_story_completeness(self, request: StoryCompletenessRequest) -> StoryCompletenessResponse:
        """
        Analyze story completeness and identify missing elements.
        
        Args:
            request: Story completeness analysis request
            
        Returns:
            Completeness analysis with missing elements
            
        Raises:
            AIServiceError: If analysis fails
        """
        try:
            prompt = self.prompt_templates.story_completeness_analysis_prompt(
                situation=request.situation or "",
                task=request.task or "",
                action=request.action or "",
                result=request.result or ""
            )
            
            system_prompt = (
                "You are an expert at analyzing professional stories for completeness. "
                "Always respond with valid JSON format."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.2
            )
            
            try:
                response_data = json.loads(response)
                return StoryCompletenessResponse(**response_data)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse completeness analysis response: {e}")
                # Return a fallback response based on simple analysis
                situation_complete = bool(request.situation and len(request.situation.strip()) > 20)
                task_complete = bool(request.task and len(request.task.strip()) > 20)
                action_complete = bool(request.action and len(request.action.strip()) > 20)
                result_complete = bool(request.result and len(request.result.strip()) > 20)
                
                completed_sections = sum([situation_complete, task_complete, action_complete, result_complete])
                completeness_percentage = int((completed_sections / 4) * 100)
                
                return StoryCompletenessResponse(
                    situation_complete=situation_complete,
                    situation_missing=[] if situation_complete else ["Add more context and background"],
                    task_complete=task_complete,
                    task_missing=[] if task_complete else ["Clarify your specific responsibilities"],
                    action_complete=action_complete,
                    action_missing=[] if action_complete else ["Detail the steps you took"],
                    result_complete=result_complete,
                    result_missing=[] if result_complete else ["Add measurable outcomes"],
                    completeness_percentage=completeness_percentage,
                    priority_improvements=["Complete all STAR sections with specific details"]
                )
                
        except BedrockClientError as e:
            logger.error(f"Bedrock error in completeness analysis: {e}")
            raise AIServiceError(f"Completeness analysis failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in completeness analysis: {e}")
            raise AIServiceError(f"Completeness analysis failed: {e}")
    
    async def quantify_impact(self, request: ImpactQuantificationRequest) -> ImpactQuantificationResponse:
        """
        Provide impact quantification assistance for a story.
        
        Args:
            request: Impact quantification request
            
        Returns:
            Suggested metrics and quantification opportunities
            
        Raises:
            AIServiceError: If quantification fails
        """
        try:
            prompt = self.prompt_templates.impact_quantification_prompt(
                story_content=request.story_content
            )
            
            system_prompt = (
                "You are an expert at helping professionals quantify their work impact. "
                "Always respond with valid JSON format."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.3
            )
            
            try:
                response_data = json.loads(response)
                # Convert suggested_metrics to ImpactMetric objects
                metrics = [
                    ImpactMetric(**metric) for metric in response_data.get("suggested_metrics", [])
                ]
                
                return ImpactQuantificationResponse(
                    suggested_metrics=metrics,
                    quantification_opportunities=response_data.get("quantification_opportunities", []),
                    impact_categories=response_data.get("impact_categories", [])
                )
            except (json.JSONDecodeError, KeyError) as e:
                logger.error(f"Failed to parse impact quantification response: {e}")
                # Return fallback response
                return ImpactQuantificationResponse(
                    suggested_metrics=[
                        ImpactMetric(
                            metric_name="Time Saved",
                            description="Amount of time saved through your actions",
                            example_value="2 hours per week"
                        ),
                        ImpactMetric(
                            metric_name="Cost Reduction",
                            description="Financial savings achieved",
                            example_value="$10,000 annually"
                        )
                    ],
                    quantification_opportunities=[
                        "Add specific time measurements",
                        "Include financial impact where possible"
                    ],
                    impact_categories=["Efficiency", "Cost Savings"]
                )
                
        except BedrockClientError as e:
            logger.error(f"Bedrock error in impact quantification: {e}")
            raise AIServiceError(f"Impact quantification failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in impact quantification: {e}")
            raise AIServiceError(f"Impact quantification failed: {e}")
    
    async def generate_report(self, request: ReportGenerationRequest) -> ReportGenerationResponse:
        """
        Generate a professional activity report using AI.
        
        Args:
            request: Report generation request with activities and parameters
            
        Returns:
            Generated report content and metadata
            
        Raises:
            AIServiceError: If report generation fails
        """
        try:
            # Convert ActivitySummary objects to dictionaries for the prompt
            activities_dict = [
                {
                    "title": activity.title,
                    "category": activity.category,
                    "date": activity.date.isoformat(),
                    "description": activity.description,
                    "impact_level": activity.impact_level,
                    "tags": activity.tags,
                    "duration_minutes": activity.duration_minutes
                }
                for activity in request.activities
            ]
            
            prompt = self.prompt_templates.report_generation_prompt(
                activities=activities_dict,
                period_start=request.period_start,
                period_end=request.period_end,
                report_type=request.report_type
            )
            
            if request.custom_instructions:
                prompt += f"\n\nAdditional Instructions:\n{request.custom_instructions}"
            
            system_prompt = (
                "You are an expert career coach creating professional activity reports. "
                "Generate comprehensive, well-structured reports in Markdown format that "
                "highlight achievements and demonstrate professional growth."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.4,
                max_tokens=6000  # Longer reports need more tokens
            )
            
            # Extract key information from the generated report
            lines = response.split('\n')
            executive_summary = ""
            key_achievements = []
            recommendations = []
            
            # Simple parsing to extract sections
            current_section = ""
            for line in lines:
                line = line.strip()
                if "executive summary" in line.lower():
                    current_section = "summary"
                elif "key achievements" in line.lower() or "achievements" in line.lower():
                    current_section = "achievements"
                elif "recommendations" in line.lower():
                    current_section = "recommendations"
                elif line.startswith("- ") or line.startswith("* "):
                    if current_section == "achievements":
                        key_achievements.append(line[2:])
                    elif current_section == "recommendations":
                        recommendations.append(line[2:])
                elif current_section == "summary" and line and not line.startswith("#"):
                    executive_summary += line + " "
            
            word_count = len(response.split())
            
            return ReportGenerationResponse(
                report_content=response,
                executive_summary=executive_summary.strip() or "Professional activity report generated successfully.",
                key_achievements=key_achievements or ["Consistent professional activity tracking"],
                recommendations=recommendations or ["Continue tracking activities for career growth"],
                word_count=word_count
            )
            
        except BedrockClientError as e:
            logger.error(f"Bedrock error in report generation: {e}")
            raise AIServiceError(f"Report generation failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in report generation: {e}")
            raise AIServiceError(f"Report generation failed: {e}")
    
    async def analyze_activities(self, request: ActivityAnalysisRequest) -> ActivityAnalysisResponse:
        """
        Analyze activities and provide insights.
        
        Args:
            request: Activity analysis request
            
        Returns:
            Analysis insights and recommendations
            
        Raises:
            AIServiceError: If analysis fails
        """
        try:
            # Convert ActivitySummary objects to dictionaries
            activities_dict = [
                {
                    "title": activity.title,
                    "category": activity.category,
                    "date": activity.date.isoformat(),
                    "description": activity.description,
                    "impact_level": activity.impact_level,
                    "tags": activity.tags
                }
                for activity in request.activities
            ]
            
            prompt = self.prompt_templates.activity_analysis_prompt(activities_dict)
            
            system_prompt = (
                "You are an expert career analyst providing insights on professional activities. "
                "Always respond with valid JSON format."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.3
            )
            
            try:
                response_data = json.loads(response)
                return ActivityAnalysisResponse(**response_data)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse activity analysis response: {e}")
                # Return fallback analysis
                categories = {}
                total_activities = len(request.activities)
                if total_activities > 0:
                    for activity in request.activities:
                        categories[activity.category] = categories.get(activity.category, 0) + 1
                    # Convert to percentages
                    categories = {k: (v / total_activities) * 100 for k, v in categories.items()}
                
                return ActivityAnalysisResponse(
                    category_distribution=categories,
                    high_impact_themes=["Professional Development"],
                    skills_demonstrated=["Time Management", "Professional Communication"],
                    growth_areas=["Leadership", "Technical Skills"],
                    recommendations=["Continue diverse activity tracking", "Focus on high-impact activities"]
                )
                
        except BedrockClientError as e:
            logger.error(f"Bedrock error in activity analysis: {e}")
            raise AIServiceError(f"Activity analysis failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in activity analysis: {e}")
            raise AIServiceError(f"Activity analysis failed: {e}")
    
    async def suggest_activity_from_calendar(self, request: CalendarEventSuggestionRequest) -> CalendarEventSuggestionResponse:
        """
        Suggest activity entry from calendar event.
        
        Args:
            request: Calendar event suggestion request
            
        Returns:
            Suggested activity details
            
        Raises:
            AIServiceError: If suggestion fails
        """
        try:
            prompt = self.prompt_templates.calendar_activity_suggestion_prompt(
                event_title=request.event_title,
                event_description=request.event_description or "",
                attendees=request.attendees,
                duration_minutes=request.duration_minutes
            )
            
            system_prompt = (
                "You are an expert at analyzing calendar events and suggesting appropriate "
                "professional activity entries. Always respond with valid JSON format."
            )
            
            response = await self.bedrock_client.invoke_claude(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=0.3
            )
            
            try:
                response_data = json.loads(response)
                return CalendarEventSuggestionResponse(**response_data)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse calendar suggestion response: {e}")
                # Return fallback suggestion
                return CalendarEventSuggestionResponse(
                    suggested_category="Customer Engagement",
                    suggested_title=request.event_title,
                    suggested_description=f"Meeting: {request.event_title}",
                    suggested_impact_level=3,
                    suggested_tags=["meeting"],
                    confidence=50
                )
                
        except BedrockClientError as e:
            logger.error(f"Bedrock error in calendar suggestion: {e}")
            raise AIServiceError(f"Calendar suggestion failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in calendar suggestion: {e}")
            raise AIServiceError(f"Calendar suggestion failed: {e}")
    
    async def health_check(self) -> AIHealthCheckResponse:
        """
        Perform health check on AI service.
        
        Returns:
            Health check response with status and metrics
        """
        try:
            start_time = time.time()
            bedrock_healthy = await self.bedrock_client.health_check()
            response_time = (time.time() - start_time) * 1000  # Convert to milliseconds
            
            if bedrock_healthy:
                return AIHealthCheckResponse(
                    status="healthy",
                    bedrock_available=True,
                    response_time_ms=response_time
                )
            else:
                return AIHealthCheckResponse(
                    status="unhealthy",
                    bedrock_available=False,
                    response_time_ms=response_time,
                    error_message="Bedrock service is not responding"
                )
                
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return AIHealthCheckResponse(
                status="unhealthy",
                bedrock_available=False,
                error_message=str(e)
            )


# Global service instance
_ai_service: Optional[AIService] = None


def get_ai_service() -> AIService:
    """Get or create the global AI service instance."""
    global _ai_service
    if _ai_service is None:
        _ai_service = AIService()
    return _ai_service