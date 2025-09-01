#!/bin/bash

# Build PhosphorSwift as a binary XCFramework with embedded resources
# This creates a pre-compiled framework that loads instantly

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Configuration
FRAMEWORK_NAME="PhosphorSwift"
OUTPUT_DIR="$PROJECT_ROOT/build"
XCFRAMEWORK_PATH="$PROJECT_ROOT/$FRAMEWORK_NAME.xcframework"

echo "🔨 Building PhosphorSwift XCFramework..."
echo "   This will create a pre-compiled binary framework with all icons embedded"

# Clean previous builds
rm -rf "$OUTPUT_DIR"
rm -rf "$XCFRAMEWORK_PATH"
mkdir -p "$OUTPUT_DIR"

# Build for iOS Simulator
echo "📱 Building for iOS Simulator..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -archivePath "$OUTPUT_DIR/ios-simulator.xcarchive" \
    -destination "generic/platform=iOS Simulator" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
    OTHER_SWIFT_FLAGS="-Xfrontend -module-interface-preserve-types-as-written" \
    2>&1 | grep -E "^(/.+:[0-9]+:[0-9]+:|CompileSwift|Ld|CreateUniversalBinary|ProcessInfoPlistFile|CompileAssetCatalog|===)" || true

# Build for iOS Device
echo "📱 Building for iOS Device..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -archivePath "$OUTPUT_DIR/ios-device.xcarchive" \
    -destination "generic/platform=iOS" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
    OTHER_SWIFT_FLAGS="-Xfrontend -module-interface-preserve-types-as-written" \
    2>&1 | grep -E "^(/.+:[0-9]+:[0-9]+:|CompileSwift|Ld|CreateUniversalBinary|ProcessInfoPlistFile|CompileAssetCatalog|===)" || true

# Build for macOS
echo "💻 Building for macOS..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -archivePath "$OUTPUT_DIR/macos.xcarchive" \
    -destination "generic/platform=macOS" \
    -sdk macosx \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
    OTHER_SWIFT_FLAGS="-Xfrontend -module-interface-preserve-types-as-written" \
    2>&1 | grep -E "^(/.+:[0-9]+:[0-9]+:|CompileSwift|Ld|CreateUniversalBinary|ProcessInfoPlistFile|CompileAssetCatalog|===)" || true

# Create XCFramework
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$OUTPUT_DIR/ios-simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$OUTPUT_DIR/ios-device.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$OUTPUT_DIR/macos.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -output "$XCFRAMEWORK_PATH"

# Check the size
XCFRAMEWORK_SIZE=$(du -sh "$XCFRAMEWORK_PATH" | cut -f1)

echo ""
echo "✅ Successfully created $FRAMEWORK_NAME.xcframework"
echo "   Size: $XCFRAMEWORK_SIZE"
echo "   Location: $XCFRAMEWORK_PATH"
echo ""
echo "📝 To use in your project:"
echo "   1. Add $FRAMEWORK_NAME.xcframework to your project (drag & drop)"
echo "   2. Make sure 'Embed & Sign' is selected"
echo "   3. For Git LFS:"
echo "      git lfs track '*.xcframework/**/*'"
echo "      git add .gitattributes"
echo "      git add $FRAMEWORK_NAME.xcframework"
echo "      git commit -m 'Add PhosphorSwift binary framework'"
echo ""
echo "🚀 Build times will now be essentially instant!"

# Clean up build artifacts
rm -rf "$OUTPUT_DIR"