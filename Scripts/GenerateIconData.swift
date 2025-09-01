#!/usr/bin/env swift

import Foundation

// This script converts SVGs into Swift code with embedded data
// This eliminates asset catalog compilation entirely

@main
enum GenerateIconData {
    static func main() async throws {
        let fm = FileManager.default
        let svgDir = URL(fileURLWithPath: "./Sources/PhosphorSwift/Resources/SVG")
        let outputDir = URL(fileURLWithPath: "./Sources/PhosphorSwift/Generated")
        
        // Create output directory
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        // Get all SVG files
        let svgFiles = try fm.contentsOfDirectory(at: svgDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "svg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        print("Processing \(svgFiles.count) SVG files...")
        
        // Group files by base name (without weight suffix)
        var iconGroups: [String: [String: Data]] = [:]
        
        for file in svgFiles {
            let name = file.deletingPathExtension().lastPathComponent
            let data = try Data(contentsOf: file)
            
            // Determine base name and weight
            let (baseName, weight) = parseIconName(name)
            
            if iconGroups[baseName] == nil {
                iconGroups[baseName] = [:]
            }
            iconGroups[baseName]![weight] = data
        }
        
        print("Found \(iconGroups.count) unique icons")
        
        // Generate Swift files in chunks to avoid huge compilation units
        let chunkSize = 100
        let chunks = iconGroups.keys.sorted().chunked(into: chunkSize)
        
        for (index, chunk) in chunks.enumerated() {
            var output = """
            // Generated Icon Data - Chunk \(index + 1)
            // DO NOT EDIT - Auto-generated
            
            import Foundation
            
            extension IconData {
            
            """
            
            for iconName in chunk {
                let weights = iconGroups[iconName]!
                let caseName = iconName.camelCased(with: "-")
                
                // Generate data for each weight
                for (weight, data) in weights {
                    let hexString = data.hexEncodedString()
                    let funcName = weight == "regular" ? caseName : "\(caseName)_\(weight.replacingOccurrences(of: "-", with: "_"))"
                    
                    output += """
                        static let \(funcName) = Data(hexEncoded: "\(hexString)")!
                    
                    """
                }
            }
            
            output += "}\n"
            
            // Write chunk file
            let chunkFile = outputDir.appendingPathComponent("IconData_\(index + 1).swift")
            try output.write(to: chunkFile, atomically: true, encoding: .utf8)
        }
        
        // Generate the main IconData struct
        let mainOutput = """
        // Icon Data Container
        // DO NOT EDIT - Auto-generated
        
        import Foundation
        
        struct IconData {
            // Icon data is distributed across multiple files to improve compilation speed
        }
        
        extension Data {
            init?(hexEncoded string: String) {
                guard string.count % 2 == 0 else { return nil }
                
                var data = Data(capacity: string.count / 2)
                var index = string.startIndex
                
                while index < string.endIndex {
                    let nextIndex = string.index(index, offsetBy: 2)
                    guard let byte = UInt8(string[index..<nextIndex], radix: 16) else { return nil }
                    data.append(byte)
                    index = nextIndex
                }
                
                self = data
            }
            
            func hexEncodedString() -> String {
                return map { String(format: "%02x", $0) }.joined()
            }
        }
        """
        
        let mainFile = outputDir.appendingPathComponent("IconData.swift")
        try mainOutput.write(to: mainFile, atomically: true, encoding: .utf8)
        
        print("✅ Generated \(chunks.count) icon data files")
    }
    
    static func parseIconName(_ name: String) -> (baseName: String, weight: String) {
        for suffix in ["-thin", "-light", "-bold", "-fill", "-duotone"] {
            if name.hasSuffix(suffix) {
                let baseName = String(name.dropLast(suffix.count))
                return (baseName, suffix.dropFirst())
            }
        }
        return (name, "regular")
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}