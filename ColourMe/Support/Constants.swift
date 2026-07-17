import Foundation

enum Constants {
    static let openRouterBaseURL = URL(string: "https://openrouter.ai/api/v1")!
    static let defaultImageModelID = "google/gemini-2.5-flash-image"
    static let subjectModelID = "openai/gpt-4o-mini"
    static let maxConcurrentRequests = 3
    static let imageResolution = "2K"
    static let imageAspectRatio = "3:4"
    static let pageCountRange = 4...24
}
