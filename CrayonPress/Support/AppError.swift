import Foundation

enum AppError: LocalizedError {
    case missingAPIKey
    case insufficientCredits
    case badResponse(status: Int, message: String)
    case emptyImageData
    case decoding(String)
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No OpenRouter API key found. Add one in Settings."
        case .insufficientCredits:
            return "Your OpenRouter key or account is out of credits. Check your limits at openrouter.ai/credits, then try again."
        case .badResponse(let status, let message):
            return "OpenRouter request failed (HTTP \(status)): \(message)"
        case .emptyImageData:
            return "The model returned no image data."
        case .decoding(let detail):
            return "Could not read the API response: \(detail)"
        case .keychain(let status):
            return "Keychain error (status \(status))."
        }
    }
}
