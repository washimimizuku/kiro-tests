"""
AI Service API Router

Provides endpoints for AI-powered story enhancement and report generation.
"""
import logging
from typing import List
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import JSONResponse

from .service import get_ai_service, AIServiceError
from .schemas import (
    StoryEnhancementRequest, StoryEnhancementResponse,
    StoryCompletenessRequest, StoryCompletenessResponse,
    ImpactQuantificationRequest, ImpactQuantificationResponse,
    ReportGenerationRequest, ReportGenerationResponse,
    ActivityAnalysisRequest, ActivityAnalysisResponse,
    CalendarEventSuggestionRequest, CalendarEventSuggestionResponse,
    AIHealthCheckResponse
)
from app.services.auth.jwt_middleware import get_current_user
from app.schemas.auth import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["AI Services"])


@router.get("/health", response_model=AIHealthCheckResponse)
async def health_check():
    """
    Check the health of the AI service and AWS Bedrock connectivity.
    
    Returns:
        Health check response with status and metrics
    """
    try:
        ai_service = get_ai_service()
        return await ai_service.health_check()
    except Exception as e:
        logger.error(f"Health check endpoint error: {e}")
        return AIHealthCheckResponse(
            status="unhealthy",
            bedrock_available=False,
            error_message="Service unavailable"
        )


@router.post("/enhance-story", response_model=StoryEnhancementResponse)
async def enhance_story(
    request: StoryEnhancementRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Enhance a story using AI-powered suggestions.
    
    Args:
        request: Story content in STAR format
        current_user: Authenticated user
        
    Returns:
        Enhancement suggestions and scores
        
    Raises:
        HTTPException: If enhancement fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.enhance_story(request)
        
        logger.info(f"Story enhancement completed for user {current_user.id}")
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in story enhancement: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Story enhancement service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in story enhancement: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during story enhancement"
        )


@router.post("/analyze-story-completeness", response_model=StoryCompletenessResponse)
async def analyze_story_completeness(
    request: StoryCompletenessRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Analyze story completeness and identify missing elements.
    
    Args:
        request: Story content to analyze
        current_user: Authenticated user
        
    Returns:
        Completeness analysis with missing elements
        
    Raises:
        HTTPException: If analysis fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.analyze_story_completeness(request)
        
        logger.info(f"Story completeness analysis completed for user {current_user.id}")
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in completeness analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Story analysis service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in completeness analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during story analysis"
        )


@router.post("/quantify-impact", response_model=ImpactQuantificationResponse)
async def quantify_impact(
    request: ImpactQuantificationRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Provide impact quantification assistance for a story.
    
    Args:
        request: Story content to analyze for impact
        current_user: Authenticated user
        
    Returns:
        Suggested metrics and quantification opportunities
        
    Raises:
        HTTPException: If quantification fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.quantify_impact(request)
        
        logger.info(f"Impact quantification completed for user {current_user.id}")
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in impact quantification: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Impact quantification service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in impact quantification: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during impact quantification"
        )


@router.post("/generate-report", response_model=ReportGenerationResponse)
async def generate_report(
    request: ReportGenerationRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Generate a professional activity report using AI.
    
    Args:
        request: Report generation parameters and activities
        current_user: Authenticated user
        
    Returns:
        Generated report content and metadata
        
    Raises:
        HTTPException: If report generation fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.generate_report(request)
        
        logger.info(
            f"Report generation completed for user {current_user.id}, "
            f"type: {request.report_type}, activities: {len(request.activities)}"
        )
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in report generation: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Report generation service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in report generation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during report generation"
        )


@router.post("/analyze-activities", response_model=ActivityAnalysisResponse)
async def analyze_activities(
    request: ActivityAnalysisRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Analyze activities and provide insights.
    
    Args:
        request: Activities to analyze
        current_user: Authenticated user
        
    Returns:
        Analysis insights and recommendations
        
    Raises:
        HTTPException: If analysis fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.analyze_activities(request)
        
        logger.info(f"Activity analysis completed for user {current_user.id}")
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in activity analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Activity analysis service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in activity analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during activity analysis"
        )


@router.post("/suggest-activity-from-calendar", response_model=CalendarEventSuggestionResponse)
async def suggest_activity_from_calendar(
    request: CalendarEventSuggestionRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Suggest activity entry from calendar event.
    
    Args:
        request: Calendar event details
        current_user: Authenticated user
        
    Returns:
        Suggested activity details
        
    Raises:
        HTTPException: If suggestion fails
    """
    try:
        ai_service = get_ai_service()
        result = await ai_service.suggest_activity_from_calendar(request)
        
        logger.info(f"Calendar activity suggestion completed for user {current_user.id}")
        return result
        
    except AIServiceError as e:
        logger.error(f"AI service error in calendar suggestion: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Calendar suggestion service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in calendar suggestion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during calendar suggestion"
        )