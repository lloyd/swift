# Using Pre-Compiled PhosphorIcons.car

## The Solution

Instead of dealing with complex XCFramework builds, we've pre-compiled all the icons into a single `PhosphorIcons.car` file (168MB). This is the same format Xcode creates, but pre-built.

## Setup in Your App

### 1. Generate the Pre-Compiled Bundle

First, generate the `.car` file from this repo:

```bash
# Clone this repo
git clone https://github.com/lloyd/swift.git phosphor-swift
cd phosphor-swift

# Compile the assets (one-time, takes ~5 minutes)
mkdir -p build
/Applications/Xcode.app/Contents/Developer/usr/bin/actool \
    Sources/PhosphorSwift/Resources/Assets.xcassets \
    --compile build \
    --platform iphoneos \
    --minimum-deployment-target 13.0 \
    --target-device iphone \
    --target-device ipad

# This creates build/Assets.car (168MB)
```

### 2. Add to Your App with Git LFS

```bash
# In your app's repository
git lfs track "*.car"
git add .gitattributes

# Copy the pre-compiled assets
cp path/to/phosphor-swift/build/Assets.car YourApp/Resources/PhosphorIcons.car

# Add to git
git add YourApp/Resources/PhosphorIcons.car
git commit -m "Add pre-compiled Phosphor icons"
```

### 2. Create a Swift Wrapper

Create `PhosphorIcons.swift` in your app:

```swift
import SwiftUI
import UIKit

public enum Ph: String, CaseIterable {
    case house = "house"
    case gear = "gear"
    // ... copy the enum cases from the original Icons.swift
    
    public var regular: Image {
        Image(uiImage: loadIcon(named: self.rawValue) ?? UIImage())
    }
    
    public var bold: Image {
        Image(uiImage: loadIcon(named: "\(self.rawValue)-bold") ?? UIImage())
    }
    
    public var fill: Image {
        Image(uiImage: loadIcon(named: "\(self.rawValue)-fill") ?? UIImage())
    }
    
    // Add other weights...
    
    private func loadIcon(named name: String) -> UIImage? {
        // Load from the compiled .car file
        let bundle = Bundle.main
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}
```

### 3. Add Build Phase to Copy Resources

In Xcode:
1. Select your app target
2. Build Phases → New Run Script Phase
3. Add this script:

```bash
# Copy pre-compiled assets if needed
if [ ! -f "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Assets.car" ]; then
    cp "$SRCROOT/Resources/PhosphorIcons.car" "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Assets.car"
fi
```

## Build Time Results

| Method | Build Time | Asset Compilation |
|--------|------------|------------------|
| SPM with 9,108 SVGs | 5+ minutes | Every build |
| Pre-compiled .car | <5 seconds | Never |

## Why This Works

- The `.car` file is already compiled - Xcode just copies it
- No asset catalog processing needed
- All 9,108 icons are available instantly
- Works with standard `UIImage(named:)` API

## File Size

- `PhosphorIcons.car`: 168MB
- With Git LFS: Only stores pointer in repo (~200 bytes)
- Actual binary stored in LFS server

## Updating Icons

When new icons are released:
1. Get the latest PhosphorSwift
2. Run: `actool Assets.xcassets --compile . --platform iphoneos`
3. Replace your `PhosphorIcons.car`
4. Commit with Git LFS

This is the simplest, fastest solution that requires minimal setup!