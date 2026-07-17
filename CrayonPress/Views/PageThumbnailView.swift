import SwiftUI

struct PageThumbnailView: View {
    let page: GeneratedPage
    let onRegenerate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                content

                if case .generating = page.status {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.25))
                        .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    ProgressView()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !page.status.isBusy {
                    Button(action: onRegenerate) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(6)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                    .padding(8)
                    .help("Regenerate this page")
                }
            }

            Text(page.subject)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page.status {
        case .done(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                failureLabel("Image could not be read")
            }
        case .failed(let message):
            failureLabel(message)
        case .pending, .generating:
            Color.clear
        }
    }

    private func failureLabel(_ message: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption2)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
        }
    }
}
