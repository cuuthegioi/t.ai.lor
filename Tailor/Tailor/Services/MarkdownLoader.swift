import Foundation

class MarkdownLoader {
    static let shared = MarkdownLoader()
    
    private init() {}
    
    func loadPrompt(for languageMode: LanguageMode) -> String? {
        guard let bundle = Bundle.main.path(forResource: languageMode.rawValue, ofType: "md") else {
            print("Could not find markdown file for language mode: \(languageMode.rawValue)")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: bundle, encoding: .utf8)
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Error loading markdown file: \(error)")
            return nil
        }
    }
    
    func loadAllPrompts() -> [LanguageMode: String] {
        var prompts: [LanguageMode: String] = [:]
        
        for mode in LanguageMode.allCases {
            if let prompt = loadPrompt(for: mode) {
                prompts[mode] = prompt
            }
        }
        
        return prompts
    }
} 