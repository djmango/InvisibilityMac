import Combine
import OllamaKit
import os
import SwiftData
import SwiftUI
import ViewState

@Observable
final class OllamaViewModel: ObservableObject {
    static var shared: OllamaViewModel!

    private var modelContext: ModelContext
    private let logger = Logger(subsystem: "ai.grav.app", category: "OllamaViewModel")

    public var mistralDownloadProgress: Double = 0.0
    public var llavaDownloadProgress: Double = 0.0
    private var mistral_res: AnyCancellable?
    private var llava_res: AnyCancellable?

    var models: [OllamaModel] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            do {
                try await OllamaKit.shared.waitForAPI()
                await pullModels()
                try await fetch()
                await ModelWarmer.shared.warm()
            } catch {
                logger.error("Could not fetch models: \(error)")
            }
        }
    }

    func isReachable() async -> Bool {
        await OllamaKit.shared.reachable()
    }

    @MainActor
    func fetch() async throws {
        let prevModels = try fetchFromLocal()
        let newModels = try await fetchFromRemote()
        logger.debug("Fetched \(newModels.count) models")

        for model in prevModels {
            if newModels.contains(where: { $0.name == model.name }) {
                model.isAvailable = true
            } else {
                model.isAvailable = false
            }
        }

        for newModel in newModels {
            let model = OllamaModel(name: newModel.name)
            model.isAvailable = true

            modelContext.insert(model)
        }

        // Remove models that are no longer available
        for model in prevModels {
            if !model.isAvailable {
                modelContext.delete(model)
            }
        }

        try modelContext.saveChanges()
        models = try fetchFromLocal()
    }

    private func fetchFromRemote() async throws -> [OKModelResponse.Model] {
        let response = try await OllamaKit.shared.models()
        let models = response.models

        return models
    }

    private func fetchFromLocal() throws -> [OllamaModel] {
        let sortDescriptor = SortDescriptor(\OllamaModel.name)
        let fetchDescriptor = FetchDescriptor<OllamaModel>(sortBy: [sortDescriptor])
        let models = try modelContext.fetch(fetchDescriptor)

        return models
    }

    @MainActor
    func pullModels() async {
        logger.debug("Pulling models")
        let mistral = OKPullModelRequestData(name: "mistral:latest")
        mistral_res = OllamaKit.shared.pullModel(data: mistral)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logger.debug("Mistral successful download")
                        self?.mistralDownloadProgress = 1.0
                    case let .failure(error):
                        self?.logger.error("Mistral failed download \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    var progress = Double(response.completed ?? 0) / Double(response.total ?? 1)
                    self?.logger.debug("Mistral status \(response.status)")
                    // We only want to go up, not down
                    if progress > self?.mistralDownloadProgress ?? 0.0 {
                        self?.logger.debug("Mistral progress \(progress)")
                        // Do not let model go over .99 until we have success completion
                        if progress > 0.99 {
                            progress = 0.99
                        }
                        self?.mistralDownloadProgress = progress
                    }
                }
            )

        let llava = OKPullModelRequestData(name: "llava:latest")
        llava_res = OllamaKit.shared.pullModel(data: llava)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logger.debug("LLava successful download")
                        self?.llavaDownloadProgress = 1.0
                    case let .failure(error):
                        self?.logger.error("Llava failed download \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    var progress = Double(response.completed ?? 0) / Double(response.total ?? 1)
                    self?.logger.debug("Llava status \(response.status)")
                    // We only want to go up, not down
                    if progress > self?.llavaDownloadProgress ?? 0.0 {
                        self?.logger.debug("Llava progress \(progress)")
                        // Do not let model go over .99 until we have success completion
                        if progress > 0.99 {
                            progress = 0.99
                        }
                        self?.llavaDownloadProgress = progress
                    }
                }
            )

        logger.debug("Pulled models")
    }

    func fromName(_ name: String) -> OllamaModel? {
        models.first(where: { $0.name == name })
    }
}
