"""
Prompt templates for AWS Bedrock AI operations.
"""
from typing import List, Dict, Any
from datetime import date


class PromptTemplates:
    """Collection of prompt templates for different AI operations."""
    
    @staticmethod
    def story_enhancement_prompt(
        situation: str,
        task: str,
        action: str,
        result: str
    ) -> str:
        """
        Generate a prompt for story enhancement.
        
        Args:
            situation: The situation section of the STAR story
            task: The task section of the STAR story
            action: The action section of the STAR story
            result: The result section of the STAR story
            
        Returns:
            Formatted prompt for story enhancement
        """
        return f"""You are an expert career coach helping professionals write compelling success stories for performance reviews and career advancement.

Review the following customer success story written in STAR format and provide specific, actionable suggestions for improvement:

**Situation:**
{situation}

**Task:**
{task}

**Action:**
{action}

**Result:**
{result}

Please provide:
1. Specific suggestions to make each section more impactful and quantifiable
2. Recommendations for adding metrics or measurable outcomes
3. Ways to better highlight leadership, innovation, or technical expertise
4. Suggestions for making the story more concise and compelling

Format your response as JSON with the following structure:
{{
    "situation_suggestions": ["suggestion 1", "suggestion 2", ...],
    "task_suggestions": ["suggestion 1", "suggestion 2", ...],
    "action_suggestions": ["suggestion 1", "suggestion 2", ...],
    "result_suggestions": ["suggestion 1", "suggestion 2", ...],
    "overall_suggestions": ["suggestion 1", "suggestion 2", ...],
    "impact_score": <1-10>,
    "completeness_score": <1-10>
}}"""
    
    @staticmethod
    def story_completeness_analysis_prompt(
        situation: str,
        task: str,
        action: str,
        result: str
    ) -> str:
        """
        Generate a prompt for story completeness analysis.
        
        Args:
            situation: The situation section of the STAR story
            task: The task section of the STAR story
            action: The action section of the STAR story
            result: The result section of the STAR story
            
        Returns:
            Formatted prompt for completeness analysis
        """
        return f"""Analyze the following STAR format story for completeness and identify any missing or weak elements:

**Situation:**
{situation or "[EMPTY]"}

**Task:**
{task or "[EMPTY]"}

**Action:**
{action or "[EMPTY]"}

**Result:**
{result or "[EMPTY]"}

Evaluate each section and provide:
1. Whether each section is complete (has sufficient detail)
2. What specific information is missing from each section
3. Overall completeness percentage
4. Priority areas to address first

Format your response as JSON:
{{
    "situation_complete": <true/false>,
    "situation_missing": ["missing element 1", ...],
    "task_complete": <true/false>,
    "task_missing": ["missing element 1", ...],
    "action_complete": <true/false>,
    "action_missing": ["missing element 1", ...],
    "result_complete": <true/false>,
    "result_missing": ["missing element 1", ...],
    "completeness_percentage": <0-100>,
    "priority_improvements": ["improvement 1", ...]
}}"""
    
    @staticmethod
    def impact_quantification_prompt(story_content: str) -> str:
        """
        Generate a prompt for impact quantification assistance.
        
        Args:
            story_content: The full story content
            
        Returns:
            Formatted prompt for impact quantification
        """
        return f"""You are helping a professional quantify the impact of their work. Review this story and suggest specific metrics and quantifiable outcomes:

{story_content}

Provide suggestions for:
1. Quantifiable metrics that could be added (time saved, cost reduced, efficiency gained, etc.)
2. Ways to measure customer satisfaction or business impact
3. Comparative metrics (before/after, baseline vs. achieved)
4. Industry-standard KPIs that might apply

Format your response as JSON:
{{
    "suggested_metrics": [
        {{
            "metric_name": "...",
            "description": "...",
            "example_value": "..."
        }},
        ...
    ],
    "quantification_opportunities": ["opportunity 1", ...],
    "impact_categories": ["category 1", ...]
}}"""
    
    @staticmethod
    def report_generation_prompt(
        activities: List[Dict[str, Any]],
        period_start: date,
        period_end: date,
        report_type: str
    ) -> str:
        """
        Generate a prompt for report generation.
        
        Args:
            activities: List of activity dictionaries
            period_start: Start date of the reporting period
            period_end: End date of the reporting period
            report_type: Type of report (weekly, monthly, quarterly, annual)
            
        Returns:
            Formatted prompt for report generation
        """
        # Format activities for the prompt
        activities_text = "\n\n".join([
            f"**Activity {i+1}:**\n"
            f"- Title: {act.get('title', 'N/A')}\n"
            f"- Category: {act.get('category', 'N/A')}\n"
            f"- Date: {act.get('date', 'N/A')}\n"
            f"- Description: {act.get('description', 'N/A')}\n"
            f"- Impact Level: {act.get('impact_level', 'N/A')}/5\n"
            f"- Tags: {', '.join(act.get('tags', []))}"
            for i, act in enumerate(activities)
        ])
        
        return f"""You are an expert career coach creating a professional activity report for performance review purposes.

Generate a comprehensive {report_type} report for the period from {period_start} to {period_end} based on the following activities:

{activities_text}

Create a well-structured report that includes:
1. Executive Summary - High-level overview of key achievements
2. Activity Breakdown by Category - Organized summary of work by type
3. Key Achievements - Highlight the most impactful activities
4. Impact Metrics - Quantifiable outcomes and results
5. Skills Demonstrated - Technical and soft skills showcased
6. Areas of Focus - Main themes and priorities during this period
7. Recommendations - Suggestions for future focus areas

Format the report in Markdown with clear sections and bullet points. Make it professional, compelling, and suitable for performance reviews or career advancement discussions.

The report should be approximately 500-1000 words depending on the number of activities."""
    
    @staticmethod
    def activity_analysis_prompt(activities: List[Dict[str, Any]]) -> str:
        """
        Generate a prompt for activity analysis and insights.
        
        Args:
            activities: List of activity dictionaries
            
        Returns:
            Formatted prompt for activity analysis
        """
        activities_summary = "\n".join([
            f"- {act.get('category', 'Unknown')}: {act.get('title', 'N/A')} (Impact: {act.get('impact_level', 0)}/5)"
            for act in activities
        ])
        
        return f"""Analyze the following professional activities and provide insights:

{activities_summary}

Provide analysis including:
1. Distribution of work across categories
2. Patterns in high-impact activities
3. Skill areas being developed
4. Potential gaps or areas for growth
5. Recommendations for career development

Format your response as JSON:
{{
    "category_distribution": {{"category": percentage, ...}},
    "high_impact_themes": ["theme 1", ...],
    "skills_demonstrated": ["skill 1", ...],
    "growth_areas": ["area 1", ...],
    "recommendations": ["recommendation 1", ...]
}}"""
    
    @staticmethod
    def calendar_activity_suggestion_prompt(
        event_title: str,
        event_description: str,
        attendees: List[str],
        duration_minutes: int
    ) -> str:
        """
        Generate a prompt for suggesting activities from calendar events.
        
        Args:
            event_title: Title of the calendar event
            event_description: Description of the calendar event
            attendees: List of attendee names/emails
            duration_minutes: Duration of the event in minutes
            
        Returns:
            Formatted prompt for activity suggestion
        """
        attendees_text = ", ".join(attendees) if attendees else "No attendees listed"
        
        return f"""Based on the following calendar event, suggest an appropriate activity entry for a professional activity tracker:

**Event Title:** {event_title}
**Description:** {event_description or "No description provided"}
**Attendees:** {attendees_text}
**Duration:** {duration_minutes} minutes

Analyze the event and suggest:
1. The most appropriate activity category (Customer Engagement, Learning, Speaking, Mentoring, Technical Consultation, or Content Creation)
2. A concise activity title
3. A brief description highlighting the key purpose and outcomes
4. Suggested impact level (1-5 scale)
5. Relevant tags

Format your response as JSON:
{{
    "suggested_category": "...",
    "suggested_title": "...",
    "suggested_description": "...",
    "suggested_impact_level": <1-5>,
    "suggested_tags": ["tag1", "tag2", ...],
    "confidence": <0-100>
}}"""