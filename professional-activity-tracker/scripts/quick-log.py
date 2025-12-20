#!/usr/bin/env python3
"""
Quick Activity Logger
Fast command-line tool for logging daily activities
"""

import os
from datetime import datetime
from pathlib import Path
import argparse

class QuickLogger:
    def __init__(self, base_path="professional-activity-tracker"):
        self.base_path = Path(base_path)
        self.daily_logs_path = self.base_path / "daily-logs"
        
    def get_today_log_path(self):
        """Get path for today's log file"""
        today = datetime.now().strftime('%Y-%m-%d')
        return self.daily_logs_path / f"daily-log-{today}.md"
    
    def create_daily_log_if_not_exists(self):
        """Create today's log file from template if it doesn't exist"""
        log_path = self.get_today_log_path()
        
        if not log_path.exists():
            os.makedirs(log_path.parent, exist_ok=True)
            
            # Load template
            template_path = self.base_path / "templates" / "daily-log-template.md"
            if template_path.exists():
                with open(template_path, 'r') as f:
                    template = f.read()
                
                # Replace date placeholder
                today = datetime.now().strftime('%Y-%m-%d')
                content = template.replace('{{DATE}}', today)
                
                with open(log_path, 'w') as f:
                    f.write(content)
                
                print(f"Created daily log: {log_path}")
            else:
                print("Template not found, creating basic log")
                with open(log_path, 'w') as f:
                    f.write(f"# Daily Activity Log - {datetime.now().strftime('%Y-%m-%d')}\n\n")
        
        return log_path
    
    def add_activity(self, category, description, completed=False):
        """Add an activity to today's log"""
        log_path = self.create_daily_log_if_not_exists()
        
        with open(log_path, 'r') as f:
            content = f.read()
        
        # Find the appropriate section
        category_map = {
            'customer': '## Customer Engagements',
            'technical': '## Technical Activities', 
            'speaking': '## Speaking & Content',
            'learning': '## Learning & Development',
            'mentoring': '## Mentoring & Leadership',
            'initiative': '## Special Initiatives'
        }
        
        section_header = category_map.get(category, '## Customer Engagements')
        checkbox = '[x]' if completed else '[ ]'
        new_item = f"- {checkbox} **Activity:** {description}\n"
        
        # Insert the new item after the section header
        if section_header in content:
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.strip() == section_header:
                    # Find the next section or end of file
                    insert_pos = i + 1
                    while insert_pos < len(lines) and not lines[insert_pos].startswith('##'):
                        insert_pos += 1
                    
                    lines.insert(insert_pos, new_item.rstrip())
                    break
            
            content = '\n'.join(lines)
        else:
            # Add section if it doesn't exist
            content += f"\n{section_header}\n{new_item}"
        
        with open(log_path, 'w') as f:
            f.write(content)
        
        print(f"Added {category} activity: {description}")
    
    def mark_completed(self, search_text):
        """Mark an activity as completed by searching for text"""
        log_path = self.get_today_log_path()
        
        if not log_path.exists():
            print("No log file for today")
            return
        
        with open(log_path, 'r') as f:
            content = f.read()
        
        # Replace [ ] with [x] for matching activities
        lines = content.split('\n')
        updated = False
        
        for i, line in enumerate(lines):
            if search_text.lower() in line.lower() and '- [ ]' in line:
                lines[i] = line.replace('- [ ]', '- [x]')
                updated = True
                print(f"Marked completed: {line.strip()}")
        
        if updated:
            with open(log_path, 'w') as f:
                f.write('\n'.join(lines))
        else:
            print(f"No matching incomplete activities found for: {search_text}")
    
    def add_win(self, description):
        """Add a key win to today's log"""
        log_path = self.create_daily_log_if_not_exists()
        
        with open(log_path, 'r') as f:
            content = f.read()
        
        # Find the Notes & Reflections section
        if '**Key Wins:**' in content:
            content = content.replace('**Key Wins:** ', f'**Key Wins:** {description}; ')
        else:
            content += f"\n**Key Wins:** {description}\n"
        
        with open(log_path, 'w') as f:
            f.write(content)
        
        print(f"Added key win: {description}")

def main():
    parser = argparse.ArgumentParser(description='Quick activity logger')
    parser.add_argument('action', choices=['add', 'complete', 'win'], 
                       help='Action to perform')
    parser.add_argument('--category', '-c', 
                       choices=['customer', 'technical', 'speaking', 'learning', 'mentoring', 'initiative'],
                       default='customer', help='Activity category')
    parser.add_argument('--description', '-d', required=True, 
                       help='Activity description or search text')
    parser.add_argument('--completed', action='store_true', 
                       help='Mark as completed when adding')
    
    args = parser.parse_args()
    
    logger = QuickLogger()
    
    if args.action == 'add':
        logger.add_activity(args.category, args.description, args.completed)
    elif args.action == 'complete':
        logger.mark_completed(args.description)
    elif args.action == 'win':
        logger.add_win(args.description)

if __name__ == "__main__":
    main()