#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath

let xcassetsPath = "\(currentPath)/Sources/PhosphorSwift/Resources/Assets.xcassets"
let svgResourcesPath = "\(currentPath)/Sources/PhosphorSwift/Resources/SVG"

print("🔄 Restructuring assets to avoid Xcode compilation...")

// Create new SVG directory
try fileManager.createDirectory(atPath: svgResourcesPath, withIntermediateDirectories: true)

// Move all SVG files from .xcassets to plain directory structure
let svgPath = "\(xcassetsPath)/SVG"
if fileManager.fileExists(atPath: svgPath) {
    let iconDirs = try fileManager.contentsOfDirectory(atPath: svgPath)
        .filter { $0.hasSuffix(".imageset") }
    
    print("Moving \(iconDirs.count) icons...")
    
    for iconDir in iconDirs {
        let iconName = iconDir.replacingOccurrences(of: ".imageset", with: "")
        let sourceDir = "\(svgPath)/\(iconDir)"
        
        // Find all SVG files in the imageset
        let files = try fileManager.contentsOfDirectory(atPath: sourceDir)
            .filter { $0.hasSuffix(".svg") }
        
        for file in files {
            let sourcePath = "\(sourceDir)/\(file)"
            let destPath = "\(svgResourcesPath)/\(file)"
            
            // Copy the SVG file
            if !fileManager.fileExists(atPath: destPath) {
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
    }
    
    print("✅ Moved all SVG files to Resources/SVG")
    print("🗑  Removing old .xcassets structure...")
    
    // Remove the old xcassets directory
    try fileManager.removeItem(atPath: xcassetsPath)
    
    print("✅ Done! Assets are now in a simple directory structure")
    print("   This will prevent Xcode from recompiling them every build")
}