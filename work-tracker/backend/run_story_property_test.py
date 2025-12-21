#!/usr/bin/env python3
"""
Story Property Test Runner

Runs property-based tests for story management functionality.
Uses Poetry for virtual environment management.
"""

import subprocess
import sys
import os

def run_story_property_tests():
    """Run story property-based tests using pytest and hypothesis."""
    
    # Change to backend directory
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    print("Running Story Property-Based Tests...")
    print("=" * 50)
    
    # Run the specific story property tests
    cmd = [
        "poetry", "run", "python", "-m", "pytest", 
        "tests/test_story_properties.py",
        "-v",
        "--tb=short",
        "--hypothesis-show-statistics"
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("STDOUT:")
        print(result.stdout)
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        print("\n✅ Story property tests completed successfully!")
        return True
        
    except subprocess.CalledProcessError as e:
        print("❌ Story property tests failed!")
        print("STDOUT:")
        print(e.stdout)
        print("STDERR:")
        print(e.stderr)
        print(f"Return code: {e.returncode}")
        return False
    except Exception as e:
        print(f"❌ Error running story property tests: {e}")
        return False

if __name__ == "__main__":
    success = run_story_property_tests()
    sys.exit(0 if success else 1)