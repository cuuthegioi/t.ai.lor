import Foundation

/// Hardcoded meta prompt: tailor text for non-native English speakers.
private let tailorSystemPrompt = """
You are a helpful writing assistant for non-native English speakers. Your task is to improve the given text so it sounds natural, clear, and professional in English while keeping the original meaning and intent.

Rules:
- Fix grammar, word choice, and phrasing.
- Keep the same tone (formal/casual) as the original.
- Do not add explanations or meta-commentary—output only the revised text.
- If the text is already clear and natural, suggest a minimal polish or return it as-is.
"""

enum GeminiError: Error {
    case missingApiKey
    case invalidResponse
    case networkError(Error)
}

/// Same model as points-estimator
private let geminiModel = "gemini-2.0-flash"

func tailorWithGemini(text: String, apiKey: String?) async throws -> String {
    guard let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty else {
        throw GeminiError.missingApiKey
    }

    let prompt = tailorSystemPrompt + "\n\nText to tailor:\n" + text
    let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(geminiModel):generateContent")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

    let body: [String: Any] = [
        "contents": [
            [
                "role": "user",
                "parts": [["text": prompt]]
            ]
        ]
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)
    
    if let http = response as? HTTPURLResponse, http.statusCode == 429 {
        throw GeminiError.networkError(NSError(domain: "Gemini", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded (429). Try again in a minute."]))
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let candidates = json["candidates"] as? [[String: Any]],
          let first = candidates.first,
          let content = first["content"] as? [String: Any],
          let parts = content["parts"] as? [[String: Any]],
          let firstPart = parts.first,
          let resultText = firstPart["text"] as? String else {
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = errorJson["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw GeminiError.networkError(NSError(domain: "Gemini", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        throw GeminiError.invalidResponse
    }

    return resultText.trimmingCharacters(in: .whitespacesAndNewlines)
}
