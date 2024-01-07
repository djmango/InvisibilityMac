import OllamaKit
import os
import SwiftData
import SwiftUI
import ViewState

@Observable
final class OllamaViewModel: ObservableObject {
    public let ollamaKit = OllamaKit.shared
    private var modelContext: ModelContext
    private var healthCheckTimer: Timer?
    private let logger = Logger(subsystem: "pro.piedpiper.app", category: "OllamaViewModel")

    var models: [OllamaModel] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        //        self.startHealthCheck()
    }

    func isReachable() async -> Bool {
        await ollamaKit.reachable()
    }

    func startHealthCheck() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            // Call the async function from the main queue
            DispatchQueue.main.async {
                Task {
                    let reachable = await self.ollamaKit.reachable()
                    self.logger.debug("Reachable: \(reachable)")
                }
            }
        }
    }

    func stopHealthCheck() {
        healthCheckTimer?.invalidate()
    }

    @MainActor
    func fetch() async throws {
        let prevModels = try fetchFromLocal()
        let newModels = try await fetchFromRemote()

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

        try modelContext.saveChanges()
        models = try fetchFromLocal()
    }

    private func fetchFromRemote() async throws -> [OKModelResponse.Model] {
        let response = try await ollamaKit.models()

        // TODO: FIND A PLACE FOR THIS
        let req = OKPullModelRequestData(name: "mistral:latest")
        try await ollamaKit.pullModel(data: req)

        let models = response.models

        return models
    }

    private func fetchFromLocal() throws -> [OllamaModel] {
        let sortDescriptor = SortDescriptor(\OllamaModel.name)
        let fetchDescriptor = FetchDescriptor<OllamaModel>(sortBy: [sortDescriptor])
        let models = try modelContext.fetch(fetchDescriptor)

        return models
    }

    static func example(modelContainer: ModelContainer) -> OllamaViewModel {
        let example = OllamaViewModel(modelContext: ModelContext(modelContainer))
        return example
    }
}
