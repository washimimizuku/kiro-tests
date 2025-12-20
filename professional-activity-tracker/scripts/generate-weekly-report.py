#!/usr/bin/env python3
"""
Weekly Report Generator
Processes daily logs and generates weekly summary reports
"""

import os
import re
from datetime import datetime, timedelta
from pathlib import Path
import argparse

class WeeklyReportGenerator:
    def __init__(self, base_path="professional-activity-tracker"):
        self.base_path = Path(base_path)
        self.daily_logs_path = self.base_path / "daily-logs"
        self.reports_path = self.base_path / "reports"
        
    def get_week_files(self, start_date):
        """Get all daily log files for a given week"""
        week_files = []
        for i in range(7):
            date = start_date + timedelta(days=i)
            filename = f"daily-log-{date.strftime('%Y-%m-%d')}.md"
            filepath = self.daily_logs_path / filename
            if filepath.exists():
                week_files.append(filepath)
        return week_files
    
    def parse_daily_log(self, filepath):
        """Extract activities from a daily log file"""
        activities = {
            'customer_engagements': [],
            'technical_activities': [],
            'speaking_content': [],
            'learning': [],
            'mentoring': [],
            'special_initiatives': [],
            'key_wins': [],
            'challenges': []
        }
        
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Extract completed activities (marked with [x])
        completed_items = re.findall(r'- \[x\] (.+)', content)
        
        # Extract key wins and challenges
        wins_match = re.search(r'\*\*Key Wins:\*\* (.+)', content)
        if wins_match:
            activities['key_wins'].append(wins_match.group(1))
            
        challenges_match = re.search(r'\*\*Challenges:\*\* (.+)', content)
        if challenges_match:
            activities['challenges'].append(challenges_match.group(1))
        
        return activities, completed_items
    
    def generate_weekly_report(self, week_start_date):
        """Generate comprehensive weekly report"""
        week_files = self.get_week_files(week_start_date)
        
        if not week_files:
            print(f"No daily logs found for week starting {week_start_date}")
            return
        
        # Aggregate data from all daily logs
        all_activities = []
        all_wins = []
        all_challenges = []
        
        for filepath in week_files:
            activities, completed_items = self.parse_daily_log(filepath)
            all_activities.extend(completed_items)
            all_wins.extend(activities['key_wins'])
            all_challenges.extend(activities['challenges'])
        
        # Generate report
        week_end = week_start_date + timedelta(days=6)
        report_content = self.create_report_content(
            week_start_date, week_end, all_activities, all_wins, all_challenges
        )
        
        # Save report
        report_filename = f"weekly-report-{week_start_date.strftime('%Y-%m-%d')}.md"
        report_path = self.reports_path / "weekly" / report_filename
        
        os.makedirs(report_path.parent, exist_ok=True)
        
        with open(report_path, 'w') as f:
            f.write(report_content)
        
        print(f"Weekly report generated: {report_path}")
        return report_path
    
    def create_report_content(self, start_date, end_date, activities, wins, challenges):
        """Create formatted report content"""
        return f"""# Weekly Report: {start_date.strftime('%B %d')} - {end_date.strftime('%B %d, %Y')}

## Executive Summary
**Activities Completed:** {len(activities)}
**Key Wins:** {len(wins)}
**Challenges Addressed:** {len(challenges)}

## Key Accomplishments
{chr(10).join(f"- {win}" for win in wins) if wins else "- No key wins recorded"}

## Activities Summary
{chr(10).join(f"- {activity}" for activity in activities[:10]) if activities else "- No activities recorded"}
{f"... and {len(activities) - 10} more activities" if len(activities) > 10 else ""}

## Challenges & Learnings
{chr(10).join(f"- {challenge}" for challenge in challenges) if challenges else "- No challenges recorded"}

## Metrics
- **Total Activities:** {len(activities)}
- **Daily Average:** {len(activities) / 7:.1f}
- **Productivity Score:** {min(100, len(activities) * 5)}%

## Next Week Focus Areas
- [ ] Follow up on key customer engagements
- [ ] Continue progress on special initiatives
- [ ] Address any outstanding challenges

---
**Report Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}
**Period:** {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}
"""

def main():
    parser = argparse.ArgumentParser(description='Generate weekly activity report')
    parser.add_argument('--date', type=str, help='Week start date (YYYY-MM-DD)', 
                       default=datetime.now().strftime('%Y-%m-%d'))
    
    args = parser.parse_args()
    
    try:
        start_date = datetime.strptime(args.date, '%Y-%m-%d').date()
        # Adjust to Monday of the week
        start_date = start_date - timedelta(days=start_date.weekday())
    except ValueError:
        print("Invalid date format. Use YYYY-MM-DD")
        return
    
    generator = WeeklyReportGenerator()
    generator.generate_weekly_report(start_date)

if __name__ == "__main__":
    main()