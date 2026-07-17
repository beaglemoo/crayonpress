import Foundation

struct OpenRouterClient: Sendable {
    private let session = URLSession.shared

    func listImageModels() async throws -> [ImageModel] {
        async let pricingTask = try? listModelPricing()
        let request = try makeRequest(path: "images/models", method: "GET")
        let response: ImageModelsResponse = try await send(request, logKind: "models")
        let pricing = await pricingTask ?? [:]
        return response.data
            .map {
                ImageModel(
                    id: $0.id,
                    name: $0.name,
                    supportedParameters: $0.supportedParameters ?? [],
                    resolutionOptions: $0.resolutionOptions,
                    pricePerImageToken: pricing[$0.id]
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Key budget and account credits, for diagnostics.
    func keyStatus() async throws -> KeyStatus {
        async let keyReq: KeyResponse = send(try makeRequest(path: "key", method: "GET"), logKind: "credits")
        async let creditsReq: CreditsResponse? = try? send(try makeRequest(path: "credits", method: "GET"), logKind: "credits")
        let key = try await keyReq
        let credits = await creditsReq
        var remaining: Double?
        if let total = credits?.data.totalCredits, let used = credits?.data.totalUsage {
            remaining = total - used
        }
        return KeyStatus(
            dailyLimit: key.data.limit,
            limitRemaining: key.data.limitRemaining,
            usageToday: key.data.usageDaily,
            accountCreditsRemaining: remaining
        )
    }

    /// Pricing only exists on the general models endpoint, not images/models.
    func listModelPricing() async throws -> [String: Double] {
        let request = try makeRequest(
            path: "models",
            method: "GET",
            queryItems: [URLQueryItem(name: "output_modalities", value: "image")]
        )
        let response: ModelsPricingResponse = try await send(request, logKind: "pricing")
        return response.data.reduce(into: [:]) { result, item in
            if let raw = item.pricing?.imageOutput, let price = Double(raw), price > 0 {
                result[item.id] = price
            }
        }
    }

    func generatePageSubjects(theme: String, count: Int, complexity: ComplexityLevel) async throws -> [String] {
        let prompt = """
        List \(count) distinct scene ideas for a children's colouring book about "\(theme)".
        \(complexity.promptModifier)
        Reply with exactly one idea per line, no numbering, no bullets, no extra text.
        Each idea is a short visual description of a single scene, at most 15 words.
        """
        let body = ChatRequest(
            model: Constants.subjectModelID,
            messages: [ChatMessage(role: "user", content: prompt)]
        )
        let request = try makeRequest(path: "chat/completions", method: "POST", body: body)
        let response: ChatResponse = try await send(request, logKind: "subjects", logModel: Constants.subjectModelID)
        guard let content = response.choices.first?.message.content else { return [] }
        var seen = Set<String>()
        let subjects = content
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
        return Array(subjects.prefix(count))
    }

    struct GeneratedImage: Sendable {
        let data: Data
        let cost: Double?
    }

    func generateImage(model: ImageModel, prompt: String, tier: QualityTier, seed: Int?) async throws -> GeneratedImage {
        var body = ImagesRequestBody(model: model.id, prompt: prompt)
        if model.supports("output_format") { body.outputFormat = "png" }
        if model.supports("aspect_ratio") { body.aspectRatio = Constants.imageAspectRatio }
        if model.supports("resolution") {
            body.resolution = tier.resolution(from: model.resolutionOptions.isEmpty ? ["1K"] : model.resolutionOptions)
        }
        if model.supports("seed") { body.seed = seed }
        // Pin quality explicitly: "auto" can silently pick high, which costs
        // ~4x for the same line art.
        if model.supports("quality") { body.quality = tier.openAIQuality }

        let request = try makeRequest(path: "images", method: "POST", body: body)
        let response: ImagesResponse = try await send(request, retryOnRateLimit: true, logKind: "image", logModel: model.id)
        guard let b64 = response.data.first?.b64Json,
              let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else {
            throw AppError.emptyImageData
        }
        return GeneratedImage(data: data, cost: response.usage?.cost)
    }

    // MARK: - Plumbing

    private func makeRequest(path: String, method: String, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
        guard let key = KeychainStore.load(), !key.isEmpty else { throw AppError.missingAPIKey }
        var url = Constants.openRouterBaseURL.appending(path: path)
        if let queryItems {
            url.append(queryItems: queryItems)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 180
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/beaglemoo/colourme", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("ColourMe", forHTTPHeaderField: "X-Title")
        return request
    }

    private func makeRequest(path: String, method: String, body: some Encodable) throws -> URLRequest {
        var request = try makeRequest(path: path, method: method)
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func send<Response: Decodable>(
        _ request: URLRequest, retryOnRateLimit: Bool = false,
        logKind: String = "request", logModel: String = "-"
    ) async throws -> Response {
        let start = Date()
        do {
            let (data, urlResponse) = try await session.data(for: request)
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0

            if status == 429 && retryOnRateLimit {
                log(kind: logKind, model: logModel, success: false, detail: "HTTP 429, retrying in 3s", cost: nil, start: start)
                try await Task.sleep(for: .seconds(3))
                return try await send(request, logKind: logKind, logModel: logModel)
            }

            guard (200..<300).contains(status) else {
                let message = (try? JSONDecoder().decode(OpenRouterErrorEnvelope.self, from: data))?.error.message
                    ?? String(data: data.prefix(300), encoding: .utf8)
                    ?? "no details"
                log(kind: logKind, model: logModel, success: false, detail: "HTTP \(status): \(message)", cost: nil, start: start)
                if status == 402 || message.localizedCaseInsensitiveContains("credit") {
                    throw AppError.insufficientCredits
                }
                throw AppError.badResponse(status: status, message: message)
            }

            do {
                let decoded = try JSONDecoder().decode(Response.self, from: data)
                let cost = (decoded as? ImagesResponse)?.usage?.cost
                log(kind: logKind, model: logModel, success: true, detail: "HTTP \(status)", cost: cost, start: start)
                return decoded
            } catch {
                log(kind: logKind, model: logModel, success: false, detail: "decode failed: \(error)", cost: nil, start: start)
                throw AppError.decoding(String(describing: error))
            }
        } catch let error as AppError {
            throw error
        } catch {
            log(kind: logKind, model: logModel, success: false, detail: error.localizedDescription, cost: nil, start: start)
            throw error
        }
    }

    private func log(kind: String, model: String, success: Bool, detail: String, cost: Double?, start: Date) {
        let durationMs = Int(Date().timeIntervalSince(start) * 1000)
        Task { @MainActor in
            ActivityLog.shared.record(
                kind: kind, model: model, success: success,
                detail: detail, cost: cost, durationMs: durationMs
            )
        }
    }
}
