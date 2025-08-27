import Foundation

enum LanguageMode: String, CaseIterable, Identifiable {
    case formal = "formal"
    case casual = "casual"
    case friendly = "friendly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .formal:
            return "Formal"
        case .casual:
            return "Casual"
        case .friendly:
            return "Friendly"
        }
    }
    
    var description: String {
        switch self {
        case .formal:
            return "Professional and business-appropriate language"
        case .casual:
            return "Relaxed and informal communication"
        case .friendly:
            return "Warm and approachable tone"
        }
    }
    
    var fileName: String {
        return "\(rawValue).md"
    }
} 