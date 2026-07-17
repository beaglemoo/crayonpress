import Foundation

enum PageStatus: Sendable {
    case pending
    case generating
    case done(Data)
    case failed(String)

    var imageData: Data? {
        if case .done(let data) = self { return data }
        return nil
    }

    var isBusy: Bool {
        switch self {
        case .pending, .generating: return true
        case .done, .failed: return false
        }
    }
}

struct GeneratedPage: Identifiable, Sendable {
    let id = UUID()
    var index: Int
    var subject: String
    var status: PageStatus = .pending
}
