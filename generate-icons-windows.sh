#!/bin/bash

echo "🎨 Generating Windows icons from SVG..."

# Check if required tools are installed
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick convert not found. Install with: brew install imagemagick"
    exit 1
fi

# Create directory for generated icons
mkdir -p assets/generated

# Generate PNG sizes needed for Windows ICO
sizes=(16 32 48 64 128 256)
for size in "${sizes[@]}"; do
    echo "  Generating ${size}x${size} PNG..."
    rsvg-convert -w $size -h $size assets/yakety.svg -o assets/generated/icon_${size}x${size}.png
done

# Create ICO file with multiple sizes
echo "  Creating yakety.ico..."
convert assets/generated/icon_16x16.png \
        assets/generated/icon_32x32.png \
        assets/generated/icon_48x48.png \
        assets/generated/icon_64x64.png \
        assets/generated/icon_128x128.png \
        assets/generated/icon_256x256.png \
        assets/yakety.ico

echo "✅ Windows icons generated!"
echo "   - assets/yakety.ico (for exe and tray)"