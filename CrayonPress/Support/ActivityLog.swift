import Foundation
import Observation

/// Session-only ring buffer of every OpenRouter interaction, for the
/// Activity Log window. Newest entries first.
@MainActor
@Observable
final class ActivityLog {
    static let shared = ActivityLog()

    struct Entry: Identifiable {
        let id = UUID()
        let date: Date
        let kind: String
        let model: String
        let success: Bool
        let detail: String
        let cost: Double?
        let durationMs: Int
    }

    private(set) var entries: [Entry] = []
    var keyStatus: KeyStatus?

    private init() {}

    func record(kind: String, model: String, success: Bool, detail: String, cost: Double?, durationMs: Int) {
        entries.insert(
            Entry(date: Date(), kind: kind, model: model, success: success,
                  detail: detail, cost: cost, durationMs: durationMs),
            at: 0
        )
        if entries.count > 200 {
            entries.removeLast(entries.count - 200)
        }
    }

    var asText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return entries.reversed().map { entry in
            let cost = entry.cost.map { String(format: " $%.4f", $0) } ?? ""
            return "\(formatter.string(from: entry.date)) [\(entry.kind)] \(entry.model) \(entry.success ? "ok" : "FAILED") (\(entry.durationMs)ms)\(cost) \(entry.detail)"
        }.joined(separator: "\n")
    }
}

struct KeyStatus: Sendable {
    var dailyLimit: Double?
    var limitRemaining: Double?
    var usageToday: Double?
    var accountCreditsRemaining: Double?
}
