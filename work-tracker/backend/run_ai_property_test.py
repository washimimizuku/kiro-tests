#!/usr/bin/env python3
"""
AI Property Test Runner

Runs property-based tests for AI service functionality using Hypothesis.
Tests universal properties that should hold for all AI operations.
"""
import sys
import subprocess
import os

def main():
    """Run AI property-based tests."""
    print("🤖 Running AI Service Property-Based Tests...")
    print("=" * 60)
    
    # Change to backend directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Run property tests with Poetry
    cmd = [
        "poetry", "run", "python", "-m", "pytest", 
        "tests/test_ai_properties.py",
        "-v",
        "--tb=short",
        "-x"  # Stop on first failure
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        print("\n✅ All AI property tests passed!")
        return 0
    except subprocess.CalledProcessError as e:
        print("❌ AI property tests failed!")
        print("STDOUT:", e.stdout)
        print("STDERR:", e.stderr)
        return 1
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())