import SwiftUI

@main
struct ColourMeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 600)
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }
    }
}
