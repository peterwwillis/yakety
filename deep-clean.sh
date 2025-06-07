#!/bin/bash

echo "🚨 DEEP CLEAN - This will remove everything including whisper.cpp!"
echo "   This action cannot be undone."
echo ""
echo "   This will remove:"
echo "   - All build directories"
echo "   - All generated files"
echo "   - The entire whisper.cpp directory"
echo "   - All downloaded models"
echo ""
echo "   Are you sure? (type 'yes' to confirm)"

read -r response
if [ "$response" != "yes" ]; then
    echo "❌ Cancelled."
    exit 0
fi

echo ""
echo "🧹 Starting deep clean..."

# First run normal clean
./clean.sh --all < /dev/null

# Remove the entire whisper.cpp directory
if [ -d "whisper.cpp" ]; then
    echo "  Removing entire whisper.cpp directory..."
    rm -rf whisper.cpp
fi

# Remove any test files
if [ -d "test" ]; then
    echo "  Remove test directory? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf test
    fi
fi

# Remove dist directory if exists
if [ -d "dist" ]; then
    echo "  Removing dist/"
    rm -rf dist
fi

# Remove any log files
find . -name "*.log" -delete 2>/dev/null

# Remove any temporary files
find . -name "*~" -delete 2>/dev/null
find . -name "*.tmp" -delete 2>/dev/null

echo ""
echo "✅ Deep clean complete!"
echo ""
echo "To rebuild from scratch:"
echo "  1. Run ./build.sh - it will clone whisper.cpp and download models"
echo "  2. Everything will be rebuilt from source"