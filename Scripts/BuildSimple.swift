//
//  BuildSimple.swift
//  PhosphorSwift
//
//  Simplified build script for non-xcassets structure
//

import Foundation

@main
enum BuildSimple {
    static func main() async throws {
        let startTime = Date()
        
        // Copy SVGs from core to Resources/SVG (if needed)
        let copied = try await copySVGFiles()
        
        // Generate Icons.swift enum
        let icons = try await generateIconsEnum()
        
        let elapsed = Date().timeIntervalSince(startTime)
        print("✅ Build completed in \(String(format: "%.2f", elapsed)) seconds")
        print("   SVG files copied: \(copied)")
        print("   Icons available: \(icons.count)")
    }
}

func copySVGFiles() async throws -> Int {
    let fm = FileManager.default
    let coreDir = URL(fileURLWithPath: "./core/assets", isDirectory: true)
    let svgDir = URL(fileURLWithPath: "./Sources/PhosphorSwift/Resources/SVG", isDirectory: true)
    
    // Create SVG directory if needed
    try fm.createDirectory(at: svgDir, withIntermediateDirectories: true)
    
    // Collect all SVG files from core
    var svgFiles: [URL] = []
    if let enumerator = fm.enumerator(at: coreDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "svg" {
                svgFiles.append(fileURL)
            }
        }
    }
    
    print("Found \(svgFiles.count) SVG files in core/assets")
    
    // Copy files (only if newer or missing)
    var copiedCount = 0
    for sourceFile in svgFiles {
        let fileName = sourceFile.lastPathComponent
        let destFile = svgDir.appendingPathComponent(fileName)
        
        // Check if we need to copy
        var shouldCopy = false
        if fm.fileExists(atPath: destFile.path()) {
            // Compare modification dates
            if let sourceDate = try? sourceFile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               let destDate = try? destFile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                shouldCopy = sourceDate > destDate
            }
        } else {
            shouldCopy = true
        }
        
        if shouldCopy {
            try? fm.removeItem(at: destFile)
            try fm.copyItem(at: sourceFile, to: destFile)
            copiedCount += 1
        }
    }
    
    return copiedCount
}

func generateIconsEnum() async throws -> Set<String> {
    let fm = FileManager.default
    let svgDir = URL(fileURLWithPath: "./Sources/PhosphorSwift/Resources/SVG", isDirectory: true)
    let outputFile = URL(fileURLWithPath: "./Sources/PhosphorSwift/Icons.swift")
    
    // Get all SVG files
    let svgFiles = try fm.contentsOfDirectory(at: svgDir, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "svg" }
    
    // Extract base icon names (without weight suffixes)
    var iconNames = Set<String>()
    for file in svgFiles {
        let name = file.deletingPathExtension().lastPathComponent
        if !(name.hasSuffix("-thin") || name.hasSuffix("-light") || 
             name.hasSuffix("-bold") || name.hasSuffix("-fill") || 
             name.hasSuffix("-duotone")) {
            iconNames.insert(name)
        }
    }
    
    // Check if Icons.swift needs updating
    var needsUpdate = true
    if fm.fileExists(atPath: outputFile.path()) {
        if let existingContent = try? String(contentsOf: outputFile, encoding: .utf8),
           existingContent.contains("// Icon count: \(iconNames.count)") {
            needsUpdate = false
        }
    }
    
    if needsUpdate {
        // Generate the Swift enum
        var output = """
        //
        //  Icons.swift
        //  PhosphorSwift - Auto Generated
        //
        //  Icon count: \(iconNames.count)
        //
        
        import Foundation
        
        public enum Ph: String, CaseIterable {
        
        """
        
        // Add all icon cases
        for name in iconNames.sorted() {
            let caseName = name.camelCased(with: "-")
            // Escape Swift keywords
            let escapedCase = caseName == "repeat" ? "`repeat`" : caseName
            output += "    case \(escapedCase) = \"\(name)\"\n"
        }
        
        output += "}\n"
        
        // Write the file
        try output.write(to: outputFile, atomically: true, encoding: .utf8)
        print("Generated Icons.swift with \(iconNames.count) icons")
    } else {
        print("Icons.swift is up to date")
    }
    
    return iconNames
}

extension String {
    func camelCased(with separator: Character) -> String {
        return self.lowercased()
            .split(separator: separator)
            .enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
            .joined()
    }
}