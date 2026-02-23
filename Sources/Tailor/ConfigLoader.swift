import Foundation

/// Load configuration from .xcconfig file (Xcode configuration file format)
func loadXcconfig(from path: String = "Config.xcconfig") -> [String: String] {
    var config: [String: String] = [:]
    
    // Try to find .xcconfig file in current directory or project root
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    
    // Try multiple possible locations
    let possiblePaths = [
        currentDir + "/" + path,
        (currentDir as NSString).deletingLastPathComponent + "/" + path,
        (currentDir as NSString).appendingPathComponent(path)
    ]
    
    guard let configPath = possiblePaths.first(where: { fileManager.fileExists(atPath: $0) }) else {
        return config
    }
    
    guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
        return config
    }
    
    let lines = content.components(separatedBy: .newlines)
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip empty lines and comments (// or #)
        if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
            continue
        }
        
        // Parse KEY = VALUE (with spaces around =)
        if let equalsIndex = trimmed.firstIndex(of: "=") {
            let key = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            var value = String(trimmed[trimmed.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove quotes if present
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || 
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            
            if !key.isEmpty {
                config[key] = value
            }
        }
    }
    
    return config
}

/// Get configuration value from .xcconfig file or system environment
func getConfig(_ key: String) -> String? {
    // First check system environment (takes precedence)
    if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
        return value
    }
    
    // Then check .xcconfig file
    let config = loadXcconfig()
    return config[key]
}
