#!/usr/bin/env python3
"""
Setup script for Professional Activity Tracker
Creates directory structure and sample files
"""

import os
from datetime import datetime
from pathlib import Path

def create_directory_structure():
    """Create the complete directory structure"""
    base_path = Path("professional-activity-tracker")
    
    directories = [
        "daily-logs",
        "stories",
        "speaking",
        "learning", 
        "mentoring",
        "reports/weekly",
        "reports/monthly",
        "reports/quarterly",
        "reports/annual",
        "templates",
        "scripts"
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        os.makedirs(dir_path, exist_ok=True)
        print(f"Created directory: {dir_path}")

def create_sample_files():
    """Create sample files to demonstrate the system"""
    base_path = Path("professional-activity-tracker")
    
    # Create today's daily log
    today = datetime.now().strftime('%Y-%m-%d')
    daily_log_path = base_path / "daily-logs" / f"daily-log-{today}.md"
    
    if not daily_log_path.exists():
        # Load template and create today's log
        template_path = base_path / "templates" / "daily-log-template.md"
        if template_path.exists():
            with open(template_path, 'r') as f:
                template = f.read()
            
            content = template.replace('{{DATE}}', today)
            
            with open(daily_log_path, 'w') as f:
                f.write(content)
            
            print(f"Created today's daily log: {daily_log_path}")
    
    # Create sample customer story
    sample_story_path = base_path / "stories" / "sample-customer-story.md"
    if not sample_story_path.exists():
        template_path = base_path / "templates" / "customer-story-template.md"
        if template_path.exists():
            with open(template_path, 'r') as f:
                template = f.read()
            
            sample_content = template.replace('{{DATE}}', today)
            sample_content = sample_content.replace('**Customer/Partner:** ', '**Customer/Partner:** Sample Corp')
            sample_content = sample_content.replace('**Industry:** ', '**Industry:** Technology')
            
            with open(sample_story_path, 'w') as f:
                f.write(sample_content)
            
            print(f"Created sample story: {sample_story_path}")

def create_usage_guide():
    """Create a quick usage guide"""
    base_path = Path("professional-activity-tracker")
    guide_path = base_path / "USAGE_GUIDE.md"
    
    guide_content = """# Professional Activity Tracker - Usage Guide

## Quick Start Commands

### Daily Logging
```bash
# Add a customer activity
python scripts/quick-log.py add -c customer -d "Met with Acme Corp to discuss data platform migration"

# Add a technical activity  
python scripts/quick-log.py add -c technical -d "Reviewed architecture for real-time analytics solution"

# Add a learning activity
python scripts/quick-log.py add -c learning -d "Completed AWS Machine Learning Specialty certification"

# Mark an activity as completed
python scripts/quick-log.py complete -d "Acme Corp"

# Add a key win
python scripts/quick-log.py win -d "Closed $2M deal with strategic partner"
```

### Report Generation
```bash
# Generate this week's report
python scripts/generate-weekly-report.py

# Generate last week's report
python scripts/generate-weekly-report.py --date 2024-12-09

# Generate this month's report
python scripts/generate-monthly-report.py

# Generate specific month report
python scripts/generate-monthly-report.py --year 2024 --month 11
```

## Daily Workflow

1. **Morning**: Create/open today's daily log
2. **Throughout day**: Use quick-log.py to add activities
3. **End of day**: Review and mark activities complete, add key wins
4. **Weekly**: Generate weekly report for review
5. **Monthly**: Generate monthly report with top customer stories

## File Organization

- `daily-logs/`: One file per day with all activities
- `stories/`: Detailed customer success stories using STAR format
- `reports/`: Generated weekly, monthly, quarterly reports
- `templates/`: Templates for consistent formatting
- `scripts/`: Automation tools for logging and reporting

## Best Practices

1. **Log activities immediately** - Don't wait until end of day
2. **Use specific, measurable descriptions** - Include outcomes and impact
3. **Create customer stories within 24 hours** - While details are fresh
4. **Review weekly reports** - Identify patterns and improvement areas
5. **Select best stories monthly** - For performance reviews and presentations

## Integration with Career Goals

This system supports your transition to independent consulting by:
- Building a portfolio of documented successes
- Creating content for LinkedIn posts and articles
- Providing metrics for business development
- Tracking learning progress toward expertise goals
- Maintaining relationships and follow-up opportunities
"""

    with open(guide_path, 'w') as f:
        f.write(guide_content)
    
    print(f"Created usage guide: {guide_path}")

def make_scripts_executable():
    """Make Python scripts executable"""
    base_path = Path("professional-activity-tracker")
    script_files = [
        "scripts/quick-log.py",
        "scripts/generate-weekly-report.py", 
        "scripts/generate-monthly-report.py"
    ]
    
    for script in script_files:
        script_path = base_path / script
        if script_path.exists():
            os.chmod(script_path, 0o755)
            print(f"Made executable: {script_path}")

def main():
    print("Setting up Professional Activity Tracker...")
    
    create_directory_structure()
    create_sample_files()
    create_usage_guide()
    make_scripts_executable()
    
    print("\n✅ Setup complete!")
    print("\nNext steps:")
    print("1. cd professional-activity-tracker")
    print("2. python scripts/quick-log.py add -c customer -d 'Your first activity'")
    print("3. Check daily-logs/ for today's file")
    print("4. Read USAGE_GUIDE.md for detailed instructions")

if __name__ == "__main__":
    main()