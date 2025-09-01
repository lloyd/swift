#!/usr/bin/env swift

import Foundation

// This script pre-compiles the asset catalog into a binary .car file
// that can be included directly in the package, avoiding recompilation

let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath

// Paths
let assetsPath = "\(currentPath)/Sources/PhosphorSwift/Resources/Assets.xcassets"
let outputPath = "\(currentPath)/Sources/PhosphorSwift/Resources"
let carFilePath = "\(outputPath)/PhosphorIcons.car"

// Check if assets exist
guard fileManager.fileExists(atPath: assetsPath) else {
    print("❌ Assets.xcassets not found at: \(assetsPath)")
    exit(1)
}

// Create output directory if needed
try fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true)

print("🔨 Compiling asset catalog...")
print("   Source: \(assetsPath)")
print("   Output: \(carFilePath)")

// Use actool to compile the asset catalog into a .car file
let process = Process()
process.executableURL = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer/usr/bin/actool")
process.arguments = [
    assetsPath,
    "--compile", outputPath,
    "--platform", "iphoneos",
    "--minimum-deployment-target", "13.0",
    "--target-device", "universal",
    "--output-format", "human-readable-text",
    "--compress-pngs",
    "--enable-on-demand-resources", "NO",
    "--app-icon", "AppIcon",
    "--output-partial-info-plist", "\(outputPath)/AssetInfo.plist"
]

// Capture output
let pipe = Pipe()
process.standardOutput = pipe
process.standardError = pipe

do {
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        // Check file size
        if let attrs = try? fileManager.attributesOfItem(atPath: carFilePath),
           let fileSize = attrs[.size] as? Int64 {
            let sizeMB = Double(fileSize) / (1024 * 1024)
            print("✅ Successfully compiled assets!")
            print("   Output size: \(String(format: "%.1f", sizeMB)) MB")
        }
    } else {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("❌ Asset compilation failed:")
            print(output)
        }
        exit(1)
    }
} catch {
    print("❌ Failed to run actool: \(error)")
    exit(1)
}