#!/usr/bin/env python3
"""
Monthly Report Generator
Creates comprehensive monthly reports with top customer stories
"""

import os
import re
from datetime import datetime, timedelta
from pathlib import Path
import argparse
import glob

class MonthlyReportGenerator:
    def __init__(self, base_path="professional-activity-tracker"):
        self.base_path = Path(base_path)
        self.stories_path = self.base_path / "stories"
        self.daily_logs_path = self.base_path / "daily-logs"
        self.reports_path = self.base_path / "reports"
        
    def get_month_stories(self, year, month):
        """Get all customer stories for a given month"""
        stories = []
        story_files = glob.glob(str(self.stories_path / "*.md"))
        
        for filepath in story_files:
            with open(filepath, 'r') as f:
                content = f.read()
                
            # Extract date from story
            date_match = re.search(r'\*\*Date:\*\* (\d{4}-\d{2}-\d{2})', content)
            if date_match:
                story_date = datetime.strptime(date_match.group(1), '%Y-%m-%d')
                if story_date.year == year and story_date.month == month:
                    # Extract story quality rating
                    rating_match = re.search(r'\*\*Story Quality Rating:\*\* \((\d)\)', content)
                    rating = int(rating_match.group(1)) if rating_match else 0
                    
                    # Extract customer name
                    customer_match = re.search(r'\*\*Customer/Partner:\*\* (.+)', content)
                    customer = customer_match.group(1) if customer_match else "Unknown"
                    
                    stories.append({
                        'filepath': filepath,
                        'date': story_date,
                        'customer': customer,
                        'rating': rating,
                        'content': content
                    })
        
        return sorted(stories, key=lambda x: x['rating'], reverse=True)
    
    def get_month_activities(self, year, month):
        """Aggregate activities for the month from daily logs"""
        activities = {
            'customer_engagements': 0,
            'technical_activities': 0,
            'speaking_content': 0,
            'learning': 0,
            'mentoring': 0,
            'total_activities': 0
        }
        
        # Get all daily logs for the month
        log_files = glob.glob(str(self.daily_logs_path / f"daily-log-{year:04d}-{month:02d}-*.md"))
        
        for filepath in log_files:
            with open(filepath, 'r') as f:
                content = f.read()
                
            # Count completed activities by section
            customer_items = len(re.findall(r'## Customer Engagements.*?(?=##|\Z)', content, re.DOTALL))
            technical_items = len(re.findall(r'## Technical Activities.*?(?=##|\Z)', content, re.DOTALL))
            speaking_items = len(re.findall(r'## Speaking & Content.*?(?=##|\Z)', content, re.DOTALL))
            learning_items = len(re.findall(r'## Learning & Development.*?(?=##|\Z)', content, re.DOTALL))
            mentoring_items = len(re.findall(r'## Mentoring & Leadership.*?(?=##|\Z)', content, re.DOTALL))
            
            total_completed = len(re.findall(r'- \[x\]', content))
            
            activities['customer_engagements'] += customer_items
            activities['technical_activities'] += technical_items
            activities['speaking_content'] += speaking_items
            activities['learning'] += learning_items
            activities['mentoring'] += mentoring_items
            activities['total_activities'] += total_completed
        
        return activities
    
    def extract_story_summary(self, story_content):
        """Extract key information from a story for the report"""
        # Extract customer and situation
        customer_match = re.search(r'\*\*Customer/Partner:\*\* (.+)', story_content)
        customer = customer_match.group(1) if customer_match else "Unknown"
        
        # Extract situation (first paragraph under Situation)
        situation_match = re.search(r'### Situation\n\*\*Context and Background:\*\*\n- (.+)', story_content)
        situation = situation_match.group(1) if situation_match else "No situation described"
        
        # Extract key result
        result_match = re.search(r'- \*\*Business Impact:\*\* (.+)', story_content)
        result = result_match.group(1) if result_match else "No business impact recorded"
        
        return {
            'customer': customer,
            'situation': situation,
            'result': result
        }
    
    def generate_monthly_report(self, year, month):
        """Generate comprehensive monthly report"""
        stories = self.get_month_stories(year, month)
        activities = self.get_month_activities(year, month)
        
        # Select top 2-3 stories
        top_stories = stories[:3]
        
        # Generate report content
        report_content = self.create_monthly_report_content(year, month, top_stories, activities)
        
        # Save report
        report_filename = f"monthly-report-{year:04d}-{month:02d}.md"
        report_path = self.reports_path / "monthly" / report_filename
        
        os.makedirs(report_path.parent, exist_ok=True)
        
        with open(report_path, 'w') as f:
            f.write(report_content)
        
        print(f"Monthly report generated: {report_path}")
        return report_path
    
    def create_monthly_report_content(self, year, month, top_stories, activities):
        """Create formatted monthly report"""
        month_name = datetime(year, month, 1).strftime('%B %Y')
        
        # Create story summaries
        story_summaries = []
        for i, story in enumerate(top_stories, 1):
            summary = self.extract_story_summary(story['content'])
            story_summaries.append(f"""
### Story {i}: {summary['customer']}
**Challenge:** {summary['situation']}
**Impact:** {summary['result']}
**Quality Rating:** {story['rating']}/5
""")
        
        return f"""# Monthly Report: {month_name}

## Executive Summary
**Total Activities:** {activities['total_activities']}
**Customer Stories Created:** {len(top_stories)}
**Top Story Rating:** {top_stories[0]['rating']}/5 if top_stories else 'N/A'}

## Key Performance Metrics
- **Customer Engagements:** {activities['customer_engagements']}
- **Technical Activities:** {activities['technical_activities']}
- **Speaking & Content:** {activities['speaking_content']}
- **Learning & Development:** {activities['learning']}
- **Mentoring Activities:** {activities['mentoring']}

## Top Customer Success Stories
{''.join(story_summaries) if story_summaries else "No customer stories recorded this month"}

## Monthly Achievements
- Completed {activities['total_activities']} professional activities
- Created {len(top_stories)} documented customer success stories
- Maintained consistent daily activity logging
- {"Exceeded" if activities['total_activities'] > 60 else "Met" if activities['total_activities'] > 40 else "Below"} monthly activity targets

## Areas for Improvement
- {"Increase customer story documentation" if len(top_stories) < 2 else "Maintain story quality standards"}
- {"Boost overall activity levels" if activities['total_activities'] < 40 else "Continue current activity pace"}
- Focus on high-impact activities with measurable outcomes

## Next Month Focus
- [ ] Target {max(2, len(top_stories))} high-quality customer stories
- [ ] Maintain daily activity logging consistency
- [ ] Focus on activities with clear business impact
- [ ] Continue professional development initiatives

---
**Report Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}
**Period:** {month_name}
**Total Stories Available:** {len(top_stories)}
"""

def main():
    parser = argparse.ArgumentParser(description='Generate monthly activity report')
    parser.add_argument('--year', type=int, help='Year (YYYY)', 
                       default=datetime.now().year)
    parser.add_argument('--month', type=int, help='Month (1-12)', 
                       default=datetime.now().month)
    
    args = parser.parse_args()
    
    if not (1 <= args.month <= 12):
        print("Month must be between 1 and 12")
        return
    
    generator = MonthlyReportGenerator()
    generator.generate_monthly_report(args.year, args.month)

if __name__ == "__main__":
    main()