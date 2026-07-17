import Foundation

struct ImageModel: Identifiable, Hashable, Sendable {
    var id: String
    var name: String?
    var supportedParameters: [String]

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return id.split(separator: "/").last.map(String.init) ?? id
    }

    func supports(_ parameter: String) -> Bool {
        supportedParameters.contains(parameter)
    }

    /// Used when the live model list could not be fetched. Only universally
    /// accepted parameters are assumed.
    static func fallback(id: String) -> ImageModel {
        ImageModel(id: id, name: nil, supportedParameters: [])
    }
}
