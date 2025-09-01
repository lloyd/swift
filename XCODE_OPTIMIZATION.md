# Xcode Build Optimization for PhosphorSwift

## The Problem
Xcode recompiles the PhosphorSwift asset catalog (9,108 SVG files) on every build, taking 5+ minutes.

## Quick Fix: Xcode Configuration

### Option 1: Use Local Package (Recommended)
Instead of adding PhosphorSwift via URL, clone it locally and add as a local package:

1. Clone this repo outside your project
2. In Xcode: File → Add Package Dependencies → Add Local...
3. Select the PhosphorSwift folder
4. Build once (will be slow)
5. **Subsequent builds will be instant** because Xcode caches local packages better

### Option 2: Disable "Always Embed Swift Standard Libraries" 
In your app target's Build Settings:
- Set `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO` for Debug builds
- This prevents SPM packages from being rebuilt

### Option 3: Use Compiled XCFramework (Coming Soon)
We're working on distributing a pre-compiled XCFramework that eliminates asset compilation entirely.

## Technical Explanation
The issue is that `actool` (Apple's asset compiler) processes all 9,108 SVG files even when nothing has changed. This happens because:

1. SPM packages are rebuilt in DerivedData on every clean build
2. Asset catalogs with `.process()` directive are always recompiled
3. Xcode doesn't cache compiled assets for SPM packages effectively

## Temporary Workaround
If you need to use the package RIGHT NOW with fast builds:

1. After first build, go to DerivedData:
   ```
   ~/Library/Developer/Xcode/DerivedData/[YourApp]/SourcePackages/checkouts/swift
   ```

2. Delete the Assets.xcassets folder:
   ```bash
   rm -rf Sources/PhosphorSwift/Resources/Assets.xcassets
   ```

3. Your builds will fail but be instant. When you need icons back, clean build.

## Long-term Solution
We're restructuring the package to avoid asset catalog compilation entirely by using one of these approaches:
- Pre-compiled binary resources 
- Direct SVG data embedding
- On-demand icon loading

Stay tuned for updates!