#!/bin/bash

set -e

echo "🔏 Signing Yakety app..."

# Find the app - check both release and debug builds
if [ -d "./build/bin/Yakety.app" ]; then
    APP_PATH="./build/bin/Yakety.app"
elif [ -d "./build-debug/bin/Yakety.app" ]; then
    APP_PATH="./build-debug/bin/Yakety.app"
else
    echo "❌ App not found. Run cmake --build first."
    exit 1
fi

echo "📍 Found app at: $APP_PATH"

# Sign with ad-hoc signature (for local use)
echo "📝 Signing with ad-hoc signature..."
codesign --force --deep --sign - "$APP_PATH"

# Verify signature
echo "✅ Verifying signature..."
codesign --verify --verbose "$APP_PATH"

# Remove quarantine
echo "🔓 Removing quarantine..."
xattr -cr "$APP_PATH"

echo "✅ App signed successfully!"
echo ""
echo "You can now run:"
echo "  open $APP_PATH"