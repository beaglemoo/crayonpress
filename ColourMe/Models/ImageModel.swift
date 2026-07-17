import Foundation

struct ImageModel: Identifiable, Hashable, Sendable {
    var id: String
    var name: String?
    var supportedParameters: [String]
    var pricePerImageToken: Double?

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return id.split(separator: "/").last.map(String.init) ?? id
    }

    func supports(_ parameter: String) -> Bool {
        supportedParameters.contains(parameter)
    }

    /// Tokens billed per generated image. Not exposed by the API, but fixed
    /// per model family; verified against real billed costs (within ~15%).
    private var estimatedTokensPerImage: Double {
        if id.hasPrefix("google/") { return 1290 }
        if id.hasPrefix("openai/") { return 1610 }
        return 4096
    }

    var estimatedPricePerPage: Double? {
        guard let pricePerImageToken else { return nil }
        return pricePerImageToken * estimatedTokensPerImage
    }

    var priceLabel: String? {
        guard let price = estimatedPricePerPage else { return nil }
        return String(format: "~$%.3f/page", price)
    }

    /// Used when the live model list could not be fetched. Only universally
    /// accepted parameters are assumed.
    static func fallback(id: String) -> ImageModel {
        ImageModel(id: id, name: nil, supportedParameters: [], pricePerImageToken: nil)
    }
}
