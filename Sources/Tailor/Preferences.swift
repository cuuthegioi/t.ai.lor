import Foundation

enum Preferences {
    static let providerKey = "TailorAIProvider"
    static let providerGPT = "gpt"
    static let providerGemini = "gemini"
    static let metaPromptKey = "TailorMetaPrompt"

    static func currentProvider() -> String {
        UserDefaults.standard.string(forKey: providerKey) ?? providerGPT
    }

    static func saveProvider(_ value: String) {
        UserDefaults.standard.set(value, forKey: providerKey)
    }

    static func resolvedAPIKey() -> String? {
        KeychainStorage.loadAPIKey()
    }

    static func effectiveTailorPrompt() -> String {
        let saved = UserDefaults.standard.string(forKey: metaPromptKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = saved, !s.isEmpty { return s }
        return tailorSystemPrompt
    }

    static func saveMetaPrompt(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: metaPromptKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: metaPromptKey)
        }
        UserDefaults.standard.synchronize()
    }
}
