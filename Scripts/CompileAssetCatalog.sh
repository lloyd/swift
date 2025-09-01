#!/bin/bash

set -e

echo "🔨 Compiling Phosphor Icons asset catalog..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

ASSETS_PATH="$PROJECT_ROOT/Sources/PhosphorSwift/Resources/Assets.xcassets"
OUTPUT_DIR="$PROJECT_ROOT/Sources/PhosphorSwift/Resources"
CAR_FILE="$OUTPUT_DIR/PhosphorIcons.car"
TEMP_DIR=$(mktemp -d)

# Clean up temp dir on exit
trap "rm -rf $TEMP_DIR" EXIT

echo "Source: $ASSETS_PATH"
echo "Output: $CAR_FILE"

# Use actool to compile the asset catalog
# We compile for all platforms to create a universal binary
/Applications/Xcode.app/Contents/Developer/usr/bin/actool \
    "$ASSETS_PATH" \
    --compile "$TEMP_DIR" \
    --platform iphoneos \
    --minimum-deployment-target 13.0 \
    --target-device iphone \
    --target-device ipad \
    --output-format human-readable-text \
    --compress-pngs \
    --optimization space \
    --enable-on-demand-resources NO 2>&1 | grep -v "/* com.apple" || true

# Move the compiled .car file to our resources
if [ -f "$TEMP_DIR/Assets.car" ]; then
    mv "$TEMP_DIR/Assets.car" "$CAR_FILE"
    
    # Check size
    SIZE=$(du -h "$CAR_FILE" | cut -f1)
    echo "✅ Successfully compiled! Size: $SIZE"
    
    # Create a placeholder file to ensure the Resources directory is tracked
    echo "This directory contains compiled resources" > "$OUTPUT_DIR/.gitkeep"
else
    echo "❌ Failed to compile asset catalog"
    exit 1
fi