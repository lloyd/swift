#!/bin/bash

# Simplified framework build - iOS only for faster builds

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

FRAMEWORK_NAME="PhosphorSwift"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_PATH="$PROJECT_ROOT/$FRAMEWORK_NAME.xcframework"

echo "🚀 Building PhosphorSwift Framework (iOS only for speed)..."

# Clean
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_PATH"
mkdir -p "$BUILD_DIR"

# Build framework using swift build
echo "📦 Building with Swift Package Manager..."

# Build for iOS Simulator (arm64 for Apple Silicon Macs)
xcodebuild \
    -scheme PhosphorSwift \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -configuration Release \
    build \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO

# Find the built framework
FRAMEWORK_PATH=$(find "$BUILD_DIR" -name "PhosphorSwift.framework" -type d | head -1)

if [ -z "$FRAMEWORK_PATH" ]; then
    echo "❌ Failed to build framework"
    exit 1
fi

# Create XCFramework with just the simulator build (good enough for development)
echo "📱 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_PATH" \
    -output "$OUTPUT_PATH"

# Check size
SIZE=$(du -sh "$OUTPUT_PATH" | cut -f1)

echo ""
echo "✅ Success! PhosphorSwift.xcframework created"
echo "   Size: $SIZE"
echo "   Path: $OUTPUT_PATH"
echo ""
echo "To use in your app:"
echo "1. Copy PhosphorSwift.xcframework to your app repo"
echo "2. Drag it into Xcode"
echo "3. Set to 'Embed & Sign'"
echo ""
echo "For Git LFS (if >100MB):"
echo "  git lfs track '*.xcframework/**/*'"
echo "  git add PhosphorSwift.xcframework .gitattributes"

# Clean up
rm -rf "$BUILD_DIR"