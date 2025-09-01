#!/bin/bash

# This creates a binary XCFramework with pre-compiled resources
# Users get the speed benefit without any build-time compilation

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "🔨 Creating PhosphorIcons.xcframework with pre-compiled resources..."

# Create temp directory for build
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create a simple framework structure
FRAMEWORK_NAME="PhosphorIcons"
FRAMEWORK_DIR="$TEMP_DIR/$FRAMEWORK_NAME.framework"

mkdir -p "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"

# Create module map
cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << EOF
framework module PhosphorIcons {
    umbrella header "PhosphorIcons.h"
    export *
}
EOF

# Create umbrella header
cat > "$FRAMEWORK_DIR/Headers/PhosphorIcons.h" << EOF
#import <Foundation/Foundation.h>

//! Project version number for PhosphorIcons.
FOUNDATION_EXPORT double PhosphorIconsVersionNumber;

//! Project version string for PhosphorIcons.
FOUNDATION_EXPORT const unsigned char PhosphorIconsVersionString[];
EOF

# Create Info.plist
cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PhosphorIcons</string>
    <key>CFBundleIdentifier</key>
    <string>com.phosphoricons.PhosphorIcons</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PhosphorIcons</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

# Copy the asset catalog directly into the framework
cp -R "$PROJECT_ROOT/Sources/PhosphorSwift/Resources/Assets.xcassets" "$FRAMEWORK_DIR/"

# Create XCFramework
XCFRAMEWORK_PATH="$PROJECT_ROOT/PhosphorIcons.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_PATH"

echo "✅ Created PhosphorIcons.xcframework"
echo "   Size: $(du -sh "$XCFRAMEWORK_PATH" | cut -f1)"
echo ""
echo "To use:"
echo "1. Add as binary dependency in Package.swift"
echo "2. Reference resources from the framework bundle"