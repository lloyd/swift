//
//  Build.swift
//  PhosphorSwift
//
//  Created by Tobias Fried on 1/25/24.
//

import Foundation

@main
enum Build {
    static func main() async throws {
        let (icons, assetsChanged) = try await buildAssets()
        try await emitSource(icons: icons, forceRegenerate: assetsChanged)
    }
}

struct Contents: Codable {
    let images: [ContentImage]
    let info: ContentInfo
    let properties: ContentProperties
    
    static func forFile(filename: String) -> Self {
        return Contents(
            images: [ContentImage(filename: filename, idiom: "universal", scale: nil)],
            info: ContentInfo(author: "xcode", version: 1),
            properties: ContentProperties(
                preservesVectorRepresentation: true,
                templateRenderingIntent: "template",
                autoScaling: "auto"
            ))
    }
}

struct ContentImage: Codable {
    let filename: String
    let idiom: String
    let scale: String?
    
    init(filename: String, idiom: String, scale: String? = nil) {
        self.filename = filename
        self.idiom = idiom
        self.scale = scale
    }
}

struct ContentInfo: Codable {
    let author: String
    let version: Int
}

struct ContentProperties: Codable {
    let preservesVectorRepresentation: Bool
    let templateRenderingIntent: String
    let autoScaling: String?
    
    enum CodingKeys: String, CodingKey {
        case preservesVectorRepresentation = "preserves-vector-representation"
        case templateRenderingIntent = "template-rendering-intent"
        case autoScaling = "auto-scaling"
    }
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

func collectSVGFiles(from coreDir: URL) throws -> [URL] {
    var svgFiles: [URL] = []
    let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
    let enumerator = FileManager.default.enumerator(
        at: coreDir,
        includingPropertiesForKeys: resourceKeys,
        options: [.skipsHiddenFiles])!
    
    for case let fileURL as URL in enumerator {
        let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
        if !resourceValues.isDirectory! {
            svgFiles.append(fileURL)
        }
    }
    
    return svgFiles
}

func buildAssets() async throws -> (Set<String>, Bool) {
    let CORE_DIR = URL(fileURLWithPath: "./core/assets", isDirectory: true)
    let ASSETS_DIR = URL(fileURLWithPath: "./Sources/PhosphorSwift/Resources/Assets.xcassets/SVG", isDirectory: true)
    
    let encoder = JSONEncoder()
    
    // First, collect all SVG file URLs synchronously
    let svgFiles = try collectSVGFiles(from: CORE_DIR)
    
    // Check if we should force a full rebuild
    let forceRebuild = ProcessInfo.processInfo.environment["FORCE_REBUILD"] != nil
    
    print("Processing \(svgFiles.count) SVG files...")
    if forceRebuild {
        print("Force rebuild enabled - processing all files")
    }
    
    // Process files concurrently using TaskGroup
    let (iconNames, processedCount) = try await withThrowingTaskGroup(of: (String?, Bool).self) { group in
        var results: [String] = []
        var totalProcessed = 0
        
        // Add tasks for each SVG file
        for fileURL in svgFiles {
            group.addTask {
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                let directory = ASSETS_DIR.appendingPathComponent("\(fileName).imageset")
                let svgURL = directory.appendingPathComponent("\(fileName).svg")
                let contentsURL = directory.appendingPathComponent("Contents.json")
                
                let fm = FileManager.default
                
                // Check if we need to process this file
                var needsProcessing = forceRebuild
                
                if !forceRebuild {
                    // Check if destination files exist and are newer than source
                    if fm.fileExists(atPath: svgURL.path()) && fm.fileExists(atPath: contentsURL.path()) {
                        do {
                            let sourceModDate = try fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
                            let destSVGModDate = try svgURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
                            let destContentsModDate = try contentsURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
                            
                            // If both destination files are newer than source, skip processing
                            if destSVGModDate >= sourceModDate && destContentsModDate >= sourceModDate {
                                needsProcessing = false
                            } else {
                                needsProcessing = true
                            }
                        } catch {
                            // If we can't get modification dates, process the file to be safe
                            needsProcessing = true
                        }
                    } else {
                        // Destination files don't exist, need to process
                        needsProcessing = true
                    }
                }
                
                if needsProcessing {
                    let contents = try encoder.encode(Contents.forFile(filename: "\(fileName).svg"))
                    
                    // FileManager operations are thread-safe for different files
                    try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    
                    if fm.fileExists(atPath: svgURL.path()) {
                        try fm.removeItem(at: svgURL)
                    }
             
                    try fm.copyItem(at: fileURL, to: svgURL)
                    try contents.write(to: contentsURL, options: .atomic)
                
                    print("Processed: \(fileName)")
                } else {
                    print("Skipped (unchanged): \(fileName)")
                }
                
                // Return icon name if it's a base icon (not a weight variant)
                let iconName: String?
                if !(fileName.hasSuffix("-thin") || fileName.hasSuffix("-light") || fileName.hasSuffix("-bold") || fileName.hasSuffix("-fill") || fileName.hasSuffix("-duotone")) {
                    iconName = fileName
                } else {
                    iconName = nil
                }
                
                return (iconName, needsProcessing)
            }
        }
        
        // Collect results from all tasks
        for try await (iconName, wasProcessed) in group {
            if let iconName = iconName {
                results.append(iconName)
            }
            if wasProcessed {
                totalProcessed += 1
            }
        }
        
        return (results, totalProcessed)
    }
    
    print("Build completed: \(processedCount) files processed, \(svgFiles.count - processedCount) files skipped")
    
    return (Set(iconNames), processedCount > 0)
}

func emitSource(icons: Set<String>, forceRegenerate: Bool) async throws {
    let ICONS_SOURCE = URL(fileURLWithPath: "./Sources/PhosphorSwift/Icons.swift", isDirectory: false)
    let fm = FileManager.default
    
    // Check if Icons.swift needs to be regenerated
    let needsRegeneration: Bool
    
    if forceRegenerate || ProcessInfo.processInfo.environment["FORCE_REBUILD"] != nil {
        needsRegeneration = true
        print("Icons.swift: Regenerating due to asset changes")
    } else if !fm.fileExists(atPath: ICONS_SOURCE.path()) {
        needsRegeneration = true
        print("Icons.swift: Regenerating (file doesn't exist)")
    } else {
        needsRegeneration = false
        print("Icons.swift: Skipped (no asset changes)")
    }
    
    if !needsRegeneration {
        return
    }
    
    // Swift keywords that need to be escaped with backticks
    let swiftKeywords: Set<String> = [
        "as", "associatedtype", "associativity", "break", "case", "catch", "class",
        "continue", "convenience", "default", "defer", "deinit", "do", "dynamic",
        "else", "enum", "extension", "fallthrough", "false", "fileprivate", "final",
        "for", "func", "function", "get", "guard", "if", "import", "in", "indirect",
        "infix", "init", "inout", "internal", "is", "lazy", "left", "let", "mutating",
        "nil", "none", "nonmutating", "open", "operator", "optional", "override",
        "postfix", "precedencegroup", "prefix", "private", "protocol", "public",
        "repeat", "required", "rethrows", "return", "right", "self", "Self", "set",
        "static", "struct", "subscript", "super", "switch", "throw", "throws", "true",
        "try", "typealias", "unowned", "var", "weak", "where", "while"
    ]
    
    let enumEntries = icons.sorted().map { name in
        let camelCasedName = name.camelCased(with: "-")
        let escapedName = swiftKeywords.contains(camelCasedName) ? "`\(camelCasedName)`" : camelCasedName
        return "    case \(escapedName) = \"\(name)\""
    }
    let source = """
    //
    //  Icons.swift
    //  Phosphor Icons
    //
    //  Created by Tobias Fried on 1/22/23.
    //  GENERATED FILE
    //
    
    import SwiftUI
    
    public enum Ph: String, CaseIterable, Identifiable {
        public var id: Self { self }
    
    \(enumEntries.joined(separator: "\n"))
    }
    
    """
        
    try source.write(to: ICONS_SOURCE, atomically: true, encoding: .utf8)
    print("Icons.swift: Successfully regenerated with \(icons.count) icons")
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = args
    
    // Add timeout handling
    do {
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus
    } catch {
        print("Shell command failed: \(error)")
        return 1
    }
}
