#!/bin/bash
set -e

# Generate macOS app icons from source icon
# Requires: ImageMagick (brew install imagemagick) or sips (built-in)

SOURCE_ICON="site/public/icon.png"
OUTPUT_DIR="Chops/Resources/Assets.xcassets/AppIcon.appiconset"

echo "🎨 Generating app icons..."

if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Source icon not found: $SOURCE_ICON"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Function to generate icon using sips (built-in on macOS)
generate_icon() {
    local size=$1
    local filename=$2
    echo "  Creating ${filename} (${size}x${size})"
    sips -z "$size" "$size" "$SOURCE_ICON" --out "$OUTPUT_DIR/$filename" > /dev/null 2>&1
}

# Generate all required sizes for macOS
generate_icon 16 "icon_16x16.png"
generate_icon 32 "icon_16x16@2x.png"
generate_icon 32 "icon_32x32.png"
generate_icon 64 "icon_32x32@2x.png"
generate_icon 128 "icon_128x128.png"
generate_icon 256 "icon_128x128@2x.png"
generate_icon 256 "icon_256x256.png"
generate_icon 512 "icon_256x256@2x.png"
generate_icon 512 "icon_512x512.png"
generate_icon 1024 "icon_512x512@2x.png"

echo "✅ App icons generated successfully!"
echo "📁 Output: $OUTPUT_DIR"
