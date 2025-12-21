#!/usr/bin/env python3
"""
Run calendar integration property-based tests.

This script runs the property-based tests for calendar integration functionality
to validate the correctness properties defined in the design document.
"""

import asyncio
import sys
import subprocess
from pathlib import Path

def run_calendar_property_tests():
    """Run calendar integration property-based tests."""
    print("🧪 Running Calendar Integration Property-Based Tests")
    print("=" * 60)
    
    # Run the specific test file
    cmd = [
        "python", "-m", "pytest", 
        "tests/test_calendar_properties.py",
        "-v",
        "--tb=short",
        "--hypothesis-show-statistics"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=Path(__file__).parent)
        
        print("STDOUT:")
        print(result.stdout)
        
        if result.stderr:
            print("\nSTDERR:")
            print(result.stderr)
        
        print(f"\nTest execution completed with return code: {result.returncode}")
        
        if result.returncode == 0:
            print("✅ All calendar integration property tests passed!")
        else:
            print("❌ Some calendar integration property tests failed!")
            
        return result.returncode
        
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1

if __name__ == "__main__":
    exit_code = run_calendar_property_tests()
    sys.exit(exit_code)