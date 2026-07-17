import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("OpenRouter") {
                SecureField("API key", text: $viewModel.apiKey, prompt: Text("sk-or-..."))

                HStack {
                    Button("Save to Keychain") {
                        viewModel.saveKey()
                    }
                    .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()
                    statusView
                }

                Text("Your key is stored only in the macOS Keychain, never on disk or in the repo. Get one at openrouter.ai/keys.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: viewModel.apiKey) {
            viewModel.saveConfirmation = false
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch viewModel.testState {
        case .idle:
            if viewModel.saveConfirmation {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .testing:
            ProgressView().controlSize(.small)
        case .success(let count):
            Label("\(count) image models", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .lineLimit(2)
                .help(message)
        }
    }
}
