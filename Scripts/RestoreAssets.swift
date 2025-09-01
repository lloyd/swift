#!/usr/bin/env swift

import Foundation

// Restore the .xcassets structure from SVG files

let fm = FileManager.default
let currentPath = fm.currentDirectoryPath

let svgDir = URL(fileURLWithPath: "\(currentPath)/Sources/PhosphorSwift/Resources/SVG")
let xcassetsDir = URL(fileURLWithPath: "\(currentPath)/Sources/PhosphorSwift/Resources/Assets.xcassets")
let svgAssetsDir = xcassetsDir.appendingPathComponent("SVG")

print("🔄 Restoring Assets.xcassets structure...")

// Create xcassets structure
try fm.createDirectory(at: svgAssetsDir, withIntermediateDirectories: true)

// Create root Contents.json
let rootContents = """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try rootContents.write(to: xcassetsDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
try rootContents.write(to: svgAssetsDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

// Get all SVG files
let svgFiles = try fm.contentsOfDirectory(at: svgDir, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "svg" }

print("Processing \(svgFiles.count) SVG files...")

// Create imageset for each SVG
for svgFile in svgFiles {
    let name = svgFile.deletingPathExtension().lastPathComponent
    let imagesetDir = svgAssetsDir.appendingPathComponent("\(name).imageset")
    
    // Create imageset directory
    try fm.createDirectory(at: imagesetDir, withIntermediateDirectories: true)
    
    // Copy SVG file
    let destSVG = imagesetDir.appendingPathComponent(svgFile.lastPathComponent)
    if fm.fileExists(atPath: destSVG.path()) {
        try fm.removeItem(at: destSVG)
    }
    try fm.copyItem(at: svgFile, to: destSVG)
    
    // Create Contents.json for imageset
    let contents = """
    {
      "images" : [
        {
          "filename" : "\(svgFile.lastPathComponent)",
          "idiom" : "universal"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "properties" : {
        "preserves-vector-representation" : true,
        "template-rendering-intent" : "template"
      }
    }
    """
    try contents.write(to: imagesetDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

print("✅ Restored Assets.xcassets with \(svgFiles.count) icons")