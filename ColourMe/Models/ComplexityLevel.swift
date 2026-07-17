import Foundation

enum ComplexityLevel: String, CaseIterable, Identifiable, Codable {
    case toddler
    case youngChild
    case olderChild

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .toddler: return "Toddler"
        case .youngChild: return "Young child"
        case .olderChild: return "Older child"
        }
    }

    var promptModifier: String {
        switch self {
        case .toddler:
            return "Very simple composition with one large friendly subject, extra-thick bold outlines, big open areas to colour, no background clutter. Suitable for a toddler."
        case .youngChild:
            return "Simple scene with a clear main subject and a light background, thick clean outlines, medium-sized areas to colour. Suitable for a young child aged 4 to 7."
        case .olderChild:
            return "A fuller scene with more detail and smaller areas to colour, clean medium-weight outlines. Suitable for an older child aged 8 to 12."
        }
    }
}
