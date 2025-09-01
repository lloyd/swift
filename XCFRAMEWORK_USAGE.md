# Using PhosphorSwift as a Binary XCFramework

## Why XCFramework?

- **Instant builds** - No compilation needed, just linking
- **No asset processing** - Icons are pre-compiled into the binary
- **Smaller Git repos** - Use Git LFS for the binary (about 50-100MB)
- **Consistent performance** - No more 5-minute builds!

## Building the XCFramework

```bash
./Scripts/BuildXCFramework.sh
```

This creates `PhosphorSwift.xcframework` with all platforms (iOS, iOS Simulator, macOS).

## Integration in Your App

### Step 1: Add to Your Project

1. Copy `PhosphorSwift.xcframework` to your app's repository
2. In Xcode: Drag the `.xcframework` into your project
3. Select your app target → General → Frameworks
4. Make sure PhosphorSwift.xcframework is set to "Embed & Sign"

### Step 2: Set Up Git LFS (Recommended)

Since the framework is ~50-100MB, use Git LFS:

```bash
# In your app's repo
git lfs track "*.xcframework/**/*"
git add .gitattributes
git add PhosphorSwift.xcframework
git commit -m "Add PhosphorSwift binary framework"
```

### Step 3: Use in Code

Same API as before:
```swift
import PhosphorSwift

struct ContentView: View {
    var body: some View {
        Ph.house.regular
            .foregroundColor(.blue)
            .frame(width: 32, height: 32)
    }
}
```

## Build Time Comparison

| Method | Build Time | Notes |
|--------|------------|-------|
| SPM Package (before) | 5+ minutes | Recompiles 9,108 SVGs every build |
| XCFramework | <5 seconds | Just links pre-compiled binary |

## Updating Icons

When you need new icons:
1. Pull latest changes from PhosphorSwift
2. Run `./Scripts/BuildXCFramework.sh`
3. Replace the `.xcframework` in your app
4. Commit with Git LFS

## Advantages

✅ **100x faster builds** - From 5 minutes to 5 seconds
✅ **No SPM issues** - No more DerivedData problems
✅ **Predictable** - Same binary every time
✅ **All icons included** - Full 7,000+ icon library
✅ **Works offline** - No network dependency

## File Size

The XCFramework is approximately 50-100MB (varies based on compression and architectures included). With Git LFS, this doesn't bloat your repository.