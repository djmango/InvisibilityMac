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

    var models: [OllamaModel] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            do {
                try await fetch()
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

        // TODO: FIND A PLACE FOR THIS
        logger.debug("Pulling model")
        let req = OKPullModelRequestData(name: "mistral:latest")
        let res = OllamaKit.shared.pullModel(data: req).collect()
        logger.debug("Pulled model")

        let models = response.models

        return models
    }

    private func fetchFromLocal() throws -> [OllamaModel] {
        let sortDescriptor = SortDescriptor(\OllamaModel.name)
        let fetchDescriptor = FetchDescriptor<OllamaModel>(sortBy: [sortDescriptor])
        let models = try modelContext.fetch(fetchDescriptor)

        return models
    }

    func fromName(_ name: String) -> OllamaModel? {
        models.first(where: { $0.name == name })
    }
}
