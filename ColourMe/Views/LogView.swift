import SwiftUI

struct LogView: View {
    private var log = ActivityLog.shared
    private let client = OpenRouterClient()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                creditsSummary
                Spacer()
                Button("Check Credits") {
                    Task { await refreshCredits() }
                }
                Button("Copy All") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(log.asText, forType: .string)
                }
                .disabled(log.entries.isEmpty)
            }
            .padding(12)

            Divider()

            if log.entries.isEmpty {
                ContentUnavailableView(
                    "Nothing yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Every OpenRouter request made this session appears here.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(log.entries) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(entry.date, format: .dateTime.hour().minute().second())
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(entry.kind)
                            .frame(width: 58, alignment: .leading)
                            .foregroundStyle(.secondary)
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? .green : .red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.model == "-" ? entry.detail : "\(entry.model)  \(entry.detail)")
                                .lineLimit(2)
                        }
                        Spacer()
                        if let cost = entry.cost {
                            Text(String(format: "$%.4f", cost))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Text("\(entry.durationMs) ms")
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                    .font(.callout)
                    .listRowBackground(entry.success ? nil : Color.red.opacity(0.12))
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 640, minHeight: 360)
        .task { await refreshCredits() }
        .navigationTitle("Activity Log")
    }

    @ViewBuilder
    private var creditsSummary: some View {
        if let status = log.keyStatus {
            HStack(spacing: 14) {
                if let used = status.usageToday, let limit = status.dailyLimit {
                    Label(String(format: "Key today: $%.2f of $%.2f", used, limit), systemImage: "key")
                } else if let used = status.usageToday {
                    Label(String(format: "Key today: $%.2f", used), systemImage: "key")
                }
                if let credits = status.accountCreditsRemaining {
                    Label(String(format: "Account: $%.2f left", credits), systemImage: "creditcard")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        } else {
            Text("Credits: not checked yet")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    private func refreshCredits() async {
        log.keyStatus = try? await client.keyStatus()
    }
}
