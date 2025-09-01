#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath

let sourcePath = "\(currentPath)/Sources/PhosphorSwift/Resources/Assets.xcassets/SVG"
let outputBasePath = "\(currentPath)/Sources/PhosphorSwift/Resources"

// Clean up old catalogs
if fileManager.fileExists(atPath: "\(outputBasePath)/Assets.xcassets") {
    try? fileManager.removeItem(atPath: "\(outputBasePath)/Assets.xcassets")
}

// Get all icon directories
let iconDirs = try fileManager.contentsOfDirectory(atPath: sourcePath)
    .filter { $0.hasSuffix(".imageset") }
    .sorted()

print("Found \(iconDirs.count) icons to split")

// Split into chunks (26 chunks, one per letter, plus one for non-alphabetic)
var chunks: [String: [String]] = [:]

for iconDir in iconDirs {
    let firstChar = iconDir.prefix(1).lowercased()
    let chunkKey = firstChar >= "a" && firstChar <= "z" ? String(firstChar) : "other"
    
    if chunks[chunkKey] == nil {
        chunks[chunkKey] = []
    }
    chunks[chunkKey]?.append(iconDir)
}

print("Splitting into \(chunks.count) asset catalogs:")

// Create separate asset catalogs for each chunk
for (chunkKey, icons) in chunks.sorted(by: { $0.key < $1.key }) {
    let catalogName = "Assets_\(chunkKey)"
    let catalogPath = "\(outputBasePath)/\(catalogName).xcassets"
    let svgPath = "\(catalogPath)/SVG"
    
    // Create catalog structure
    try fileManager.createDirectory(atPath: svgPath, withIntermediateDirectories: true)
    
    // Create Contents.json for the catalog
    let catalogContents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try catalogContents.write(toPath: "\(catalogPath)/Contents.json", atomically: true, encoding: .utf8)
    try catalogContents.write(toPath: "\(svgPath)/Contents.json", atomically: true, encoding: .utf8)
    
    // Copy icons to this catalog
    for iconDir in icons {
        let sourceIconPath = "\(sourcePath)/\(iconDir)"
        let destIconPath = "\(svgPath)/\(iconDir)"
        try fileManager.copyItem(atPath: sourceIconPath, toPath: destIconPath)
    }
    
    print("  \(catalogName): \(icons.count) icons")
}

print("\n✅ Successfully split assets into \(chunks.count) catalogs")
print("This should enable parallel compilation and faster builds!")

extension String {
    func write(toPath path: String, atomically: Bool, encoding: String.Encoding) throws {
        try self.write(toFile: path, atomically: atomically, encoding: encoding)
    }
}