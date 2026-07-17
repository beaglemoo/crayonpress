import SwiftUI

@main
struct CrayonPressApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 600)
        }
        .windowResizability(.contentMinSize)
        .commands {
            DiagnosticsCommands()
        }

        Window("Activity Log", id: "activity-log") {
            LogView()
        }

        Settings {
            SettingsView()
        }
    }
}

struct DiagnosticsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Diagnostics") {
            Button("Activity Log") {
                openWindow(id: "activity-log")
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Check Credits") {
                openWindow(id: "activity-log")
                Task { @MainActor in
                    ActivityLog.shared.keyStatus = try? await OpenRouterClient().keyStatus()
                }
            }

            Divider()

            Button("Reveal Archive in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([BookStore.booksDirectory])
            }
        }
    }
}
