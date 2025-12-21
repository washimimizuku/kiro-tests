"""
Property-based tests for AI service functionality.

Tests universal properties that should hold for all AI service operations,
focusing on story enhancement and validation capabilities.
"""
import pytest
from hypothesis import given, strategies as st, settings, assume, HealthCheck
from hypothesis.strategies import composite
import asyncio
from unittest.mock import AsyncMock, patch
from datetime import date, timedelta

from app.services.ai.service import AIService, AIServiceError
from app.services.ai.schemas import (
    StoryEnhancementRequest, StoryEnhancementResponse,
    StoryCompletenessRequest, StoryCompletenessResponse,
    ReportGenerationRequest, ReportGenerationResponse,
    ActivitySummary
)


# Test data generators
@composite
def story_content(draw):
    """Generate realistic story content for testing."""
    # Generate non-empty strings with reasonable length
    situation = draw(st.text(min_size=10, max_size=500).filter(lambda x: x.strip()))
    task = draw(st.text(min_size=10, max_size=500).filter(lambda x: x.strip()))
    action = draw(st.text(min_size=10, max_size=500).filter(lambda x: x.strip()))
    result = draw(st.text(min_size=10, max_size=500).filter(lambda x: x.strip()))
    
    return {
        "situation": situation,
        "task": task,
        "action": action,
        "result": result
    }


@composite
def partial_story_content(draw):
    """Generate story content with some sections potentially empty."""
    situation = draw(st.one_of(st.none(), st.text(min_size=0, max_size=500)))
    task = draw(st.one_of(st.none(), st.text(min_size=0, max_size=500)))
    action = draw(st.one_of(st.none(), st.text(min_size=0, max_size=500)))
    result = draw(st.one_of(st.none(), st.text(min_size=0, max_size=500)))
    
    return {
        "situation": situation,
        "task": task,
        "action": action,
        "result": result
    }


@composite
def activity_list(draw):
    """Generate a list of realistic activities for testing."""
    num_activities = draw(st.integers(min_value=1, max_value=10))
    activities = []
    
    categories = ["Customer Engagement", "Learning", "Speaking", "Mentoring", "Technical Consultation"]
    
    for _ in range(num_activities):
        activity = ActivitySummary(
            title=draw(st.text(min_size=5, max_size=100).filter(lambda x: x.strip())),
            category=draw(st.sampled_from(categories)),
            date=draw(st.dates(min_value=date(2023, 1, 1), max_value=date(2024, 12, 31))),
            description=draw(st.text(min_size=10, max_size=300).filter(lambda x: x.strip())),
            impact_level=draw(st.integers(min_value=1, max_value=5)),
            tags=draw(st.lists(st.text(min_size=1, max_size=20), min_size=0, max_size=5)),
            duration_minutes=draw(st.one_of(st.none(), st.integers(min_value=15, max_value=480)))
        )
        activities.append(activity)
    
    return activities


@composite
def report_generation_request(draw):
    """Generate realistic report generation requests."""
    start_date = draw(st.dates(min_value=date(2023, 1, 1), max_value=date(2024, 6, 1)))
    end_date = draw(st.dates(min_value=start_date, max_value=start_date + timedelta(days=365)))
    
    activities = draw(activity_list())
    
    return ReportGenerationRequest(
        activities=activities,
        period_start=start_date,
        period_end=end_date,
        report_type=draw(st.sampled_from(["weekly", "monthly", "quarterly", "annual"])),
        custom_instructions=draw(st.one_of(st.none(), st.text(min_size=10, max_size=200)))
    )


class TestAIServiceProperties:
    """Property-based tests for AI service functionality."""
    
    @given(story_content())
    @settings(max_examples=3, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_story_enhancement_property(self, story_data):
        """
        Property 4: Story Enhancement and Validation
        
        For any valid story content submitted to the AI service, the system should 
        return enhancement suggestions and validate completeness according to STAR 
        format requirements.
        
        **Validates: Requirements 2.2, 2.5**
        **Feature: work-tracker, Property 4: Story Enhancement and Validation**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Mock the Bedrock client to avoid actual API calls during testing
        mock_response = {
            "situation_suggestions": ["Add more specific context"],
            "task_suggestions": ["Clarify your role"],
            "action_suggestions": ["Detail specific steps"],
            "result_suggestions": ["Quantify the outcomes"],
            "overall_suggestions": ["Include metrics"],
            "impact_score": 7,
            "completeness_score": 8
        }
        
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.return_value = str(mock_response).replace("'", '"')
            
            # Create request
            request = StoryEnhancementRequest(
                situation=story_data["situation"],
                task=story_data["task"],
                action=story_data["action"],
                result=story_data["result"]
            )
            
            # Test the property
            response = await ai_service.enhance_story(request)
            
            # Verify response structure and content
            assert isinstance(response, StoryEnhancementResponse)
            assert isinstance(response.situation_suggestions, list)
            assert isinstance(response.task_suggestions, list)
            assert isinstance(response.action_suggestions, list)
            assert isinstance(response.result_suggestions, list)
            assert isinstance(response.overall_suggestions, list)
            assert 1 <= response.impact_score <= 10
            assert 1 <= response.completeness_score <= 10
            
            # Verify that the service was called with the correct content
            mock_claude.assert_called_once()
            call_args = mock_claude.call_args
            assert story_data["situation"] in call_args[1]["prompt"]
            assert story_data["task"] in call_args[1]["prompt"]
            assert story_data["action"] in call_args[1]["prompt"]
            assert story_data["result"] in call_args[1]["prompt"]
    
    @given(partial_story_content())
    @settings(max_examples=3, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_story_completeness_analysis_property(self, story_data):
        """
        Property 4: Story Enhancement and Validation (Completeness Analysis)
        
        For any story content (including incomplete stories), the AI service should 
        analyze completeness and provide specific feedback about missing elements.
        
        **Validates: Requirements 2.2, 2.5**
        **Feature: work-tracker, Property 4: Story Enhancement and Validation**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Mock response for completeness analysis
        mock_response = {
            "situation_complete": bool(story_data.get("situation") and len(story_data["situation"].strip()) > 10),
            "situation_missing": [] if story_data.get("situation") else ["Add context"],
            "task_complete": bool(story_data.get("task") and len(story_data["task"].strip()) > 10),
            "task_missing": [] if story_data.get("task") else ["Clarify role"],
            "action_complete": bool(story_data.get("action") and len(story_data["action"].strip()) > 10),
            "action_missing": [] if story_data.get("action") else ["Detail steps"],
            "result_complete": bool(story_data.get("result") and len(story_data["result"].strip()) > 10),
            "result_missing": [] if story_data.get("result") else ["Add outcomes"],
            "completeness_percentage": 75,
            "priority_improvements": ["Complete missing sections"]
        }
        
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.return_value = str(mock_response).replace("'", '"').replace("True", "true").replace("False", "false")
            
            # Create request
            request = StoryCompletenessRequest(
                situation=story_data.get("situation"),
                task=story_data.get("task"),
                action=story_data.get("action"),
                result=story_data.get("result")
            )
            
            # Test the property
            response = await ai_service.analyze_story_completeness(request)
            
            # Verify response structure
            assert isinstance(response, StoryCompletenessResponse)
            assert isinstance(response.situation_complete, bool)
            assert isinstance(response.task_complete, bool)
            assert isinstance(response.action_complete, bool)
            assert isinstance(response.result_complete, bool)
            assert isinstance(response.situation_missing, list)
            assert isinstance(response.task_missing, list)
            assert isinstance(response.action_missing, list)
            assert isinstance(response.result_missing, list)
            assert 0 <= response.completeness_percentage <= 100
            assert isinstance(response.priority_improvements, list)
            
            # Verify logical consistency
            # If a section is complete, it should have no missing elements
            if response.situation_complete:
                assert len(response.situation_missing) == 0
            if response.task_complete:
                assert len(response.task_missing) == 0
            if response.action_complete:
                assert len(response.action_missing) == 0
            if response.result_complete:
                assert len(response.result_missing) == 0
    
    @given(st.text(min_size=1, max_size=100))
    @settings(max_examples=2, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_ai_service_error_handling_property(self, invalid_input):
        """
        Property: AI Service Error Handling
        
        For any input that causes the AI service to fail, the service should handle 
        errors gracefully and provide meaningful error messages without crashing.
        
        **Feature: work-tracker, Property: Error Handling**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Mock a Bedrock client error
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.side_effect = Exception("Simulated API error")
            
            request = StoryEnhancementRequest(
                situation=invalid_input,
                task=invalid_input,
                action=invalid_input,
                result=invalid_input
            )
            
            # The service should handle errors gracefully
            with pytest.raises(AIServiceError):
                await ai_service.enhance_story(request)
            
            # Verify the error was logged and handled properly
            mock_claude.assert_called_once()
    
    @given(story_content())
    @settings(max_examples=2, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_story_enhancement_response_consistency_property(self, story_data):
        """
        Property: Response Consistency
        
        For any valid story content, the AI service should return responses that 
        are structurally consistent and contain relevant suggestions.
        
        **Feature: work-tracker, Property: Response Consistency**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Mock consistent response structure
        mock_response = {
            "situation_suggestions": ["Suggestion 1", "Suggestion 2"],
            "task_suggestions": ["Task suggestion"],
            "action_suggestions": ["Action suggestion"],
            "result_suggestions": ["Result suggestion"],
            "overall_suggestions": ["Overall suggestion"],
            "impact_score": 6,
            "completeness_score": 7
        }
        
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.return_value = str(mock_response).replace("'", '"')
            
            request = StoryEnhancementRequest(
                situation=story_data["situation"],
                task=story_data["task"],
                action=story_data["action"],
                result=story_data["result"]
            )
            
            response = await ai_service.enhance_story(request)
            
            # Verify all suggestion lists are present and contain strings
            for suggestions in [
                response.situation_suggestions,
                response.task_suggestions,
                response.action_suggestions,
                response.result_suggestions,
                response.overall_suggestions
            ]:
                assert isinstance(suggestions, list)
                for suggestion in suggestions:
                    assert isinstance(suggestion, str)
                    assert len(suggestion.strip()) > 0  # Non-empty suggestions
            
            # Verify scores are within valid ranges
            assert 1 <= response.impact_score <= 10
            assert 1 <= response.completeness_score <= 10
    
    @given(report_generation_request())
    @settings(max_examples=2, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_report_generation_completeness_property(self, request_data):
        """
        Property 6: Report Generation Completeness
        
        For any set of user activities within a specified time period, the AI service 
        should generate a structured report that includes activity summaries, 
        categorized groupings, and impact metrics derived from the input data.
        
        **Validates: Requirements 3.1, 3.2, 4.4**
        **Feature: work-tracker, Property 6: Report Generation Completeness**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Mock response for report generation
        mock_response = f"""# {request_data.report_type.title()} Report
        
## Executive Summary
This report covers the period from {request_data.period_start} to {request_data.period_end}.

## Activity Breakdown by Category
- Customer Engagement: 3 activities
- Learning: 2 activities
- Technical Consultation: 1 activity

## Key Achievements
- Completed major customer project
- Learned new technologies
- Mentored team members

## Impact Metrics
- Customer satisfaction improved by 20%
- Team productivity increased by 15%

## Skills Demonstrated
- Technical leadership
- Problem solving
- Communication

## Areas of Focus
- Customer success
- Team development
- Technical excellence

## Recommendations
- Continue focus on customer engagement
- Expand technical mentoring
- Develop new skills in emerging technologies
"""
        
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.return_value = mock_response
            
            # Test the property
            response = await ai_service.generate_report(request_data)
            
            # Verify response structure and completeness
            assert isinstance(response, ReportGenerationResponse)
            assert isinstance(response.report_content, str)
            assert len(response.report_content.strip()) > 0
            assert isinstance(response.executive_summary, str)
            assert isinstance(response.key_achievements, list)
            assert isinstance(response.recommendations, list)
            assert isinstance(response.word_count, int)
            assert response.word_count > 0
            
            # Verify report contains expected sections
            content_lower = response.report_content.lower()
            assert any(keyword in content_lower for keyword in [
                "summary", "achievement", "activity", "impact", "skill"
            ])
            
            # Verify that the service was called with the correct data
            mock_claude.assert_called_once()
            call_args = mock_claude.call_args
            prompt = call_args[1]["prompt"]
            
            # Verify activities are included in the prompt
            assert str(request_data.period_start) in prompt
            assert str(request_data.period_end) in prompt
            assert request_data.report_type in prompt
            
            # Verify at least some activity data is in the prompt
            for activity in request_data.activities[:3]:  # Check first few activities
                assert activity.title in prompt or activity.category in prompt
    
    @given(activity_list())
    @settings(max_examples=2, deadline=10000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @pytest.mark.asyncio
    async def test_report_generation_activity_inclusion_property(self, activities):
        """
        Property: Report Generation Activity Inclusion
        
        For any list of activities provided to the report generation service, 
        the generated report should reference or include information from 
        those activities.
        
        **Feature: work-tracker, Property: Activity Inclusion**
        """
        # Create AI service instance
        ai_service = AIService()
        
        # Create a report request with the activities
        request_data = ReportGenerationRequest(
            activities=activities,
            period_start=date(2024, 1, 1),
            period_end=date(2024, 1, 31),
            report_type="monthly"
        )
        
        # Mock response that includes activity information
        activity_titles = [activity.title for activity in activities[:3]]  # Use first few
        mock_response = f"""# Monthly Report

## Executive Summary
This report covers activities including: {', '.join(activity_titles)}

## Activity Breakdown
{chr(10).join([f"- {activity.category}: {activity.title}" for activity in activities[:5]])}

## Key Achievements
- Completed various professional activities
- Demonstrated skills across multiple categories

## Recommendations
- Continue diverse activity engagement
"""
        
        with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
            mock_claude.return_value = mock_response
            
            response = await ai_service.generate_report(request_data)
            
            # Verify that the response includes activity-related content
            assert isinstance(response, ReportGenerationResponse)
            assert len(response.report_content) > 0
            
            # Verify that the prompt included the activities
            call_args = mock_claude.call_args
            prompt = call_args[1]["prompt"]
            
            # At least some activities should be mentioned in the prompt
            activity_mentions = 0
            for activity in activities:
                if activity.title in prompt or activity.category in prompt:
                    activity_mentions += 1
            
            # Should have at least some activity mentions
            assert activity_mentions > 0


# Async test runner helper
def run_async_test(coro):
    """Helper to run async tests."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


# Convert async tests to sync for pytest
class TestAIServicePropertiesSync:
    """Synchronous wrapper for async property tests."""
    
    def test_story_enhancement_property_sync(self):
        """Sync wrapper for story enhancement property test."""
        ai_service = AIService()
        
        # Test with a simple example
        story_data = {
            "situation": "Customer was experiencing slow database queries",
            "task": "Optimize database performance",
            "action": "Analyzed queries and added indexes",
            "result": "Reduced query time by 50%"
        }
        
        async def run_test():
            mock_response = {
                "situation_suggestions": ["Add more specific context"],
                "task_suggestions": ["Clarify your role"],
                "action_suggestions": ["Detail specific steps"],
                "result_suggestions": ["Quantify the outcomes"],
                "overall_suggestions": ["Include metrics"],
                "impact_score": 7,
                "completeness_score": 8
            }
            
            with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
                mock_claude.return_value = str(mock_response).replace("'", '"')
                
                request = StoryEnhancementRequest(
                    situation=story_data["situation"],
                    task=story_data["task"],
                    action=story_data["action"],
                    result=story_data["result"]
                )
                
                response = await ai_service.enhance_story(request)
                
                assert isinstance(response, StoryEnhancementResponse)
                assert 1 <= response.impact_score <= 10
                assert 1 <= response.completeness_score <= 10
        
        run_async_test(run_test())
    
    def test_story_completeness_analysis_property_sync(self):
        """Sync wrapper for story completeness analysis property test."""
        ai_service = AIService()
        
        story_data = {
            "situation": "Customer issue",
            "task": None,
            "action": "Fixed the problem",
            "result": None
        }
        
        async def run_test():
            mock_response = {
                "situation_complete": True,
                "situation_missing": [],
                "task_complete": False,
                "task_missing": ["Clarify role"],
                "action_complete": True,
                "action_missing": [],
                "result_complete": False,
                "result_missing": ["Add outcomes"],
                "completeness_percentage": 50,
                "priority_improvements": ["Complete missing sections"]
            }
            
            with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
                mock_claude.return_value = str(mock_response).replace("'", '"').replace("True", "true").replace("False", "false")
                
                request = StoryCompletenessRequest(
                    situation=story_data.get("situation"),
                    task=story_data.get("task"),
                    action=story_data.get("action"),
                    result=story_data.get("result")
                )
                
                response = await ai_service.analyze_story_completeness(request)
                
                assert isinstance(response, StoryCompletenessResponse)
                assert 0 <= response.completeness_percentage <= 100
                
                # Verify logical consistency
                if response.situation_complete:
                    assert len(response.situation_missing) == 0
                if response.task_complete:
                    assert len(response.task_missing) == 0
        
        run_async_test(run_test())
    
    def test_report_generation_completeness_property_sync(self):
        """Sync wrapper for report generation completeness property test."""
        ai_service = AIService()
        
        # Create test data
        activities = [
            ActivitySummary(
                title="Customer meeting with ABC Corp",
                category="Customer Engagement",
                date=date(2024, 1, 15),
                description="Discussed project requirements and timeline",
                impact_level=4,
                tags=["customer", "meeting"],
                duration_minutes=60
            ),
            ActivitySummary(
                title="Python training session",
                category="Learning",
                date=date(2024, 1, 20),
                description="Advanced Python concepts and best practices",
                impact_level=3,
                tags=["python", "training"],
                duration_minutes=120
            )
        ]
        
        request_data = ReportGenerationRequest(
            activities=activities,
            period_start=date(2024, 1, 1),
            period_end=date(2024, 1, 31),
            report_type="monthly"
        )
        
        async def run_test():
            mock_response = """# Monthly Report
            
## Executive Summary
This report covers January 2024 activities.

## Activity Breakdown by Category
- Customer Engagement: 1 activity
- Learning: 1 activity

## Key Achievements
- Successful customer engagement
- Completed training program

## Recommendations
- Continue customer focus
- Expand learning initiatives
"""
            
            with patch.object(ai_service.bedrock_client, 'invoke_claude', new_callable=AsyncMock) as mock_claude:
                mock_claude.return_value = mock_response
                
                response = await ai_service.generate_report(request_data)
                
                assert isinstance(response, ReportGenerationResponse)
                assert len(response.report_content.strip()) > 0
                assert isinstance(response.word_count, int)
                assert response.word_count > 0
                
                # Verify report structure
                content_lower = response.report_content.lower()
                assert "report" in content_lower
                assert any(keyword in content_lower for keyword in [
                    "summary", "achievement", "activity"
                ])
        
        run_async_test(run_test())