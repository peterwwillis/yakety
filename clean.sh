#!/bin/bash

echo "🧹 Cleaning Yakety build artifacts..."

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

# Clean whisper.cpp if requested
if [ "$1" = "--all" ] || [ "$1" = "--whisper" ]; then
    echo "🧹 Cleaning whisper.cpp..."
    
    if [ -d "whisper.cpp/build" ]; then
        echo "  Removing whisper.cpp/build/"
        rm -rf whisper.cpp/build
    fi
    
    if [ -d "whisper.cpp/build-windows" ]; then
        echo "  Removing whisper.cpp/build-windows/"
        rm -rf whisper.cpp/build-windows
    fi
    
    # Optional: remove models too
    if [ "$1" = "--all" ]; then
        echo "⚠️  Do you want to remove downloaded models too? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if [ -d "whisper.cpp/models" ]; then
                echo "  Removing whisper.cpp/models/"
                rm -rf whisper.cpp/models
            fi
        fi
    fi
fi

# Clean CMake cache files
find . -name "CMakeCache.txt" -delete 2>/dev/null
find . -name "CMakeFiles" -type d -exec rm -rf {} + 2>/dev/null

# Clean ninja files
find . -name ".ninja_deps" -delete 2>/dev/null
find . -name ".ninja_log" -delete 2>/dev/null
find . -name "build.ninja" -delete 2>/dev/null

# Clean any .DS_Store files (macOS)
find . -name ".DS_Store" -delete 2>/dev/null

echo "✅ Clean complete!"
echo ""
echo "Usage:"
echo "  ./clean.sh           - Clean yakety build files only"
echo "  ./clean.sh --whisper - Clean yakety and whisper.cpp build files"
echo "  ./clean.sh --all     - Clean everything (will ask about models)"