import Foundation

enum GPTError: Error {
    case missingApiKey
    case invalidResponse
    case networkError(Error)
}

/// OpenAI mini model (use gpt-5-mini when available if you prefer).
private let gptModel = "gpt-4o-mini"

func tailorWithGPT(text: String, apiKey: String?, systemPrompt: String) async throws -> String {
    guard let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty else {
        throw GPTError.missingApiKey
    }

    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
        "model": gptModel,
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Text to tailor:\n\n\(text)"]
        ]
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    if let http = response as? HTTPURLResponse, http.statusCode == 429 {
        throw GPTError.networkError(NSError(domain: "OpenAI", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded (429). Try again in a minute."]))
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = json["choices"] as? [[String: Any]],
          let first = choices.first,
          let message = first["message"] as? [String: Any],
          let resultText = message["content"] as? String else {
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = errorJson["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw GPTError.networkError(NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        throw GPTError.invalidResponse
    }

    return resultText.trimmingCharacters(in: .whitespacesAndNewlines)
}
