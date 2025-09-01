# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Phosphor Icons is a flexible icon family library for SwiftUI. This package provides over 7,000 icons in 6 different weights as SwiftUI Images.

## Architecture

### Core Components

- **Ph enum**: Central enumeration containing all icon names as cases (auto-generated from SVG assets)
- **IconWeight enum**: Defines 6 icon weights (regular, thin, light, bold, fill, duotone)
- **Image extensions**: Provides SwiftUI Image instances with proper interpolation and resizing
- **ColorBlended ViewModifier**: Enables color masking for icons

### Build System

The package uses a custom build script (`build.sh`) that:
1. Updates the `core` git submodule containing SVG assets
2. Runs `Scripts/Build.swift` to:
   - Copy SVG files from `core/assets` to `Sources/PhosphorSwift/Resources/Assets.xcassets/SVG`
   - Generate `Contents.json` for each icon imageset
   - Auto-generate `Sources/PhosphorSwift/Icons.swift` with all icon cases

## Commands

### Build the package
```bash
swift build
```

### Run tests
```bash
swift test
```

### Regenerate icon assets from core
```bash
./build.sh
```

### Build for specific platform
```bash
# iOS
xcodebuild -scheme PhosphorSwift -destination "platform=iOS Simulator,name=iPhone 15"

# macOS
xcodebuild -scheme PhosphorSwift -destination "platform=macOS"
```

## Package Configuration

- **Minimum Swift version**: 5.9
- **Supported platforms**: macOS 10.15+, iOS 13+, tvOS 13+
- **Resources**: The Assets.xcassets directory needs to be properly configured as a resource in Package.swift for Bundle.module to work

## Build Performance

The build system has been optimized for speed:
- **Incremental builds**: ~3 seconds (when no assets changed)
- **Clean Swift builds**: ~12 seconds  
- **Full asset regeneration**: ~25 seconds (with FORCE_REBUILD=1)
- **Parallel processing**: Utilizes all CPU cores for asset generation
- **Smart caching**: Only processes changed SVG files

To force a complete rebuild of assets:
```bash
FORCE_REBUILD=1 ./build.sh
```

## Testing

Tests are located in `Tests/PhosphorSwiftTests/`. The example app in `Example/PhosphorSwiftExample/` provides a working demonstration of the library usage.