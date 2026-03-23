import Foundation

struct AIStudioConfig {
    var endpoint: String
    var model: String
    var apiKey: String
}

enum AIStudioError: LocalizedError {
    case missingEndpoint
    case badURL
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingEndpoint:
            return "Add an API endpoint first."
        case .badURL:
            return "Invalid API endpoint URL."
        case .emptyResponse:
            return "The AI service returned an empty response."
        }
    }
}

final class AIStudioService {
    static let shared = AIStudioService()

    private init() {}

    func testConnection(config: AIStudioConfig) async throws -> String {
        let prompt = "Return exactly: CONNECTED"
        return try await generateText(prompt: prompt, config: config)
    }

    func generateText(prompt: String, config: AIStudioConfig) async throws -> String {
        let trimmedEndpoint = config.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEndpoint.isEmpty else { throw AIStudioError.missingEndpoint }
        guard let url = URL(string: trimmedEndpoint) else { throw AIStudioError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "model": config.model.isEmpty ? "gpt-4o-mini" : config.model,
            "messages": [
                ["role": "system", "content": "You are a concise product design assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.6
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)
        if let text = parseOpenAIStyleResponse(data), !text.isEmpty {
            return text
        }
        if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
            return raw
        }
        throw AIStudioError.emptyResponse
    }

    private func parseOpenAIStyleResponse(_ data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first
        else { return nil }

        if
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let text = first["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}
