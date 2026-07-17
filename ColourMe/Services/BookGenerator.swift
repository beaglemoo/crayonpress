import Foundation
import Observation

@MainActor
@Observable
final class BookGenerator {
    private(set) var pages: [GeneratedPage] = []
    private let client = OpenRouterClient()
    private var spec: BookSpec?
    private var model: ImageModel?

    var completedCount: Int {
        pages.filter { !$0.status.isBusy }.count
    }

    var isFinished: Bool {
        !pages.isEmpty && pages.allSatisfy { !$0.status.isBusy }
    }

    func generate(spec: BookSpec, model: ImageModel) async {
        self.spec = spec
        self.model = model

        var subjects = (try? await client.generatePageSubjects(
            theme: spec.theme, count: spec.pageCount, complexity: spec.complexity
        )) ?? []
        if subjects.count < spec.pageCount {
            let extras = PromptBuilder.fallbackSubjects(theme: spec.theme, count: spec.pageCount)
            subjects += extras.suffix(spec.pageCount - subjects.count)
        }

        pages = subjects.enumerated().map { GeneratedPage(index: $0.offset, subject: $0.element) }

        let batches = stride(from: 0, to: pages.count, by: Constants.maxConcurrentRequests).map {
            Array(pages.indices[$0..<min($0 + Constants.maxConcurrentRequests, pages.count)])
        }
        for batch in batches {
            await withTaskGroup(of: Void.self) { group in
                for index in batch {
                    group.addTask { await self.generatePage(at: index, seed: nil) }
                }
            }
        }
    }

    func regenerate(pageID: UUID) async {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else { return }
        await generatePage(at: index, seed: Int.random(in: 1...1_000_000))
    }

    private func generatePage(at index: Int, seed: Int?) async {
        guard let spec, let model else { return }
        pages[index].status = .generating
        let prompt = PromptBuilder.imagePrompt(subject: pages[index].subject, complexity: spec.complexity)
        do {
            let data = try await client.generateImage(model: model, prompt: prompt, seed: seed)
            pages[index].status = .done(data)
        } catch {
            pages[index].status = .failed(error.localizedDescription)
        }
    }
}
