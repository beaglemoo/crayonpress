import SwiftUI

struct ComposeBookView: View {
    @Bindable var viewModel: BookFormViewModel

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 16)]

    private var groupedPages: [(title: String, pages: [BookFormViewModel.ComposePage])] {
        Dictionary(grouping: viewModel.composePages, by: \.bookTitle)
            .map { (title: $0.key, pages: $0.value) }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                TextField("Book name, e.g. Best Bits", text: $viewModel.composeTheme)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                TextField("Child's name (optional)", text: $viewModel.composeChildName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedPages, id: \.title) { group in
                        Text(group.title)
                            .font(.headline)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(group.pages) { page in
                                composeTile(page)
                            }
                        }
                    }
                }
                .padding(28)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    viewModel.createComposedBook()
                } label: {
                    Text("Create Book (\(viewModel.composeSelection.count) pages)")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.composeSelection.isEmpty)
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.openLibrary()
                } label: {
                    Label("Library", systemImage: "arrow.backward")
                }
            }
        }
        .navigationTitle("New Book from Pages")
    }

    @ViewBuilder
    private func composeTile(_ page: BookFormViewModel.ComposePage) -> some View {
        let selectionIndex = viewModel.composeSelection.firstIndex(of: page.id)

        Button {
            viewModel.toggleComposeSelection(page.id)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if let nsImage = NSImage(data: page.image) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(.rect(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let selectionIndex {
                        Text("\(selectionIndex + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(.blue, in: .circle)
                            .padding(6)
                    }
                }
                .overlay {
                    if selectionIndex != nil {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.blue, lineWidth: 3)
                    }
                }

                Text(page.subject)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
