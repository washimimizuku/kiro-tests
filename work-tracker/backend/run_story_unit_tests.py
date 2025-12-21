#!/usr/bin/env python3
"""
Story Unit Test Runner

Runs unit tests for story service functionality.
Uses Poetry for virtual environment management.
"""

import subprocess
import sys
import os

def run_story_unit_tests():
    """Run story unit tests using pytest."""
    
    # Change to backend directory
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    print("Running Story Unit Tests...")
    print("=" * 50)
    
    # Run the specific story unit tests
    cmd = [
        "poetry", "run", "python", "-m", "pytest", 
        "tests/test_story_service.py",
        "-v",
        "--tb=short"
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("STDOUT:")
        print(result.stdout)
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        print("\n✅ Story unit tests completed successfully!")
        return True
        
    except subprocess.CalledProcessError as e:
        print("❌ Story unit tests failed!")
        print("STDOUT:")
        print(e.stdout)
        print("STDERR:")
        print(e.stderr)
        print(f"Return code: {e.returncode}")
        return False
    except Exception as e:
        print(f"❌ Error running story unit tests: {e}")
        return False

if __name__ == "__main__":
    success = run_story_unit_tests()
    sys.exit(0 if success else 1)