# Professional Activity Tracker - Usage Guide

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
