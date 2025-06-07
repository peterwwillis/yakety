#!/bin/bash

echo "🧹 Cleaning all build artifacts..."

# Clean yakety build directory
if [ -d "build" ]; then
    echo "  Removing build/"
    rm -rf build
fi

# Clean Windows cross-compilation build
if [ -d "build-windows" ]; then
    echo "  Removing build-windows/"
    rm -rf build-windows
fi

# Clean generated icons
if [ -d "assets/generated" ]; then
    echo "  Removing assets/generated/"
    rm -rf assets/generated
fi

if [ -f "assets/yakety.icns" ]; then
    echo "  Removing assets/yakety.icns"
    rm -f assets/yakety.icns
fi

if [ -d "assets/yakety.iconset" ]; then
    echo "  Removing assets/yakety.iconset/"
    rm -rf assets/yakety.iconset
fi

# Remove the entire whisper.cpp clone
if [ -d "whisper.cpp" ]; then
    echo "  Removing whisper.cpp/"
    rm -rf whisper.cpp
fi

# Clean any .DS_Store files (macOS)
find . -name ".DS_Store" -delete 2>/dev/null

echo "✅ Clean complete!"