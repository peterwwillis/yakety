#!/bin/bash

# Build script that demonstrates Whisper.cpp Ninja generator preference

set -e

echo "=== Yakety Build Script ==="
echo "This script builds Yakety, preferring Ninja generator for Whisper.cpp"
echo

# Clean previous build if requested
if [ "$1" = "clean" ]; then
    echo "Cleaning previous build..."
    rm -rf build whisper.cpp/build
    echo "Clean complete"
    echo
fi

# Check if Ninja is available
if command -v ninja &> /dev/null; then
    echo "✓ Ninja found at: $(which ninja)"
else
    echo "⚠ Ninja not found. Whisper.cpp will use the default generator."
    echo "  Install Ninja for faster builds: brew install ninja (macOS) or apt-get install ninja-build (Linux)"
fi
echo

# Configure with release preset (uses Ninja by default)
echo "Configuring build..."
cmake --preset release

echo
echo "Building..."
cmake --build --preset release

echo
echo "✅ Build complete!"
echo "   CLI executable: ./build/bin/yakety-cli"
echo "   App bundle: ./build/bin/Yakety.app (macOS only)"
echo
echo "To create distribution packages, run:"
echo "   cmake --build build --target package"