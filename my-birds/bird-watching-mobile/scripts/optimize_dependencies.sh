#!/bin/bash

# Script to analyze and optimize Flutter dependencies
# Run this before each release to identify unused dependencies

echo "==================================="
echo "Flutter Dependency Optimization"
echo "==================================="
echo ""

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

echo "1. Analyzing dependencies..."
echo "-----------------------------------"
flutter pub deps --style=compact

echo ""
echo "2. Checking for unused dependencies..."
echo "-----------------------------------"

# Get list of dependencies from pubspec.yaml
DEPS=$(grep -A 100 "dependencies:" pubspec.yaml | grep "^  [a-z]" | cut -d: -f1 | tr -d ' ')

# Check each dependency
UNUSED=()
for dep in $DEPS; do
    # Skip flutter SDK dependencies
    if [ "$dep" = "flutter" ] || [ "$dep" = "cupertino_icons" ]; then
        continue
    fi
    
    # Search for import statements
    if ! grep -r "import 'package:$dep" lib/ test/ > /dev/null 2>&1; then
        UNUSED+=("$dep")
    fi
done

if [ ${#UNUSED[@]} -eq 0 ]; then
    echo "✓ No unused dependencies found"
else
    echo "⚠ Potentially unused dependencies:"
    for dep in "${UNUSED[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Review these dependencies and remove if not needed."
fi

echo ""
echo "3. Checking for unused imports..."
echo "-----------------------------------"
dart fix --dry-run | grep "unused_import" || echo "✓ No unused imports found"

echo ""
echo "4. Analyzing package sizes..."
echo "-----------------------------------"

# Create temporary directory for analysis
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Build release APK with size analysis
echo "Building release APK for size analysis..."
flutter build apk --release --target-platform android-arm64 --analyze-size > "$TEMP_DIR/size_analysis.txt" 2>&1

# Extract size information
if [ -f "$TEMP_DIR/size_analysis.txt" ]; then
    echo ""
    echo "App size breakdown:"
    grep -A 20 "app-release.apk" "$TEMP_DIR/size_analysis.txt" || echo "Size analysis not available"
fi

echo ""
echo "5. Recommendations..."
echo "-----------------------------------"
echo "✓ Run 'dart fix --apply' to remove unused imports"
echo "✓ Review and remove unused dependencies from pubspec.yaml"
echo "✓ Enable code shrinking in release builds"
echo "✓ Use 'flutter build appbundle' for Play Store releases"
echo "✓ Optimize image assets with WebP format"
echo ""

echo "==================================="
echo "Optimization analysis complete!"
echo "==================================="
