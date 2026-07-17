import Foundation

// MARK: - Image generation

struct ImagesRequestBody: Encodable {
    let model: String
    let prompt: String
    var n = 1
    var outputFormat: String?
    var aspectRatio: String?
    var resolution: String?
    var seed: Int?

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, resolution, seed
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
    }
}

struct ImagesResponse: Decodable {
    struct Item: Decodable {
        let b64Json: String?
        let mediaType: String?

        enum CodingKeys: String, CodingKey {
            case b64Json = "b64_json"
            case mediaType = "media_type"
        }
    }

    let data: [Item]
}

// MARK: - Model discovery

struct ImageModelsResponse: Decodable {
    struct Item: Decodable {
        let id: String
        let name: String?
        let supportedParameters: [String]?

        enum CodingKeys: String, CodingKey {
            case id, name
            case supportedParameters = "supported_parameters"
        }
    }

    let data: [Item]
}

// MARK: - Chat completions (page subject ideas)

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
}

struct ChatResponse: Decodable {
    struct Choice: Decodable {
        let message: ChatMessage
    }

    let choices: [Choice]
}

// MARK: - Error envelope

struct OpenRouterErrorEnvelope: Decodable {
    struct Body: Decodable {
        let message: String?
    }

    let error: Body
}
