import SwiftData
import SwiftUI
import ViewState
import OllamaKit

@Observable
final class OllamaViewModel: ObservableObject {
    private var modelContext: ModelContext
    public let ollamaKit = OllamaKit.shared
    
    var models: [OllamaModel] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func isReachable() async -> Bool {
        await ollamaKit.reachable()
    }
    
    @MainActor
    func fetch() async throws {
        let prevModels = try self.fetchFromLocal()
        let newModels = try await self.fetchFromRemote()
        
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
            
            self.modelContext.insert(model)
        }
        
        try self.modelContext.saveChanges()
        models = try self.fetchFromLocal()
    }
    
    private func fetchFromRemote() async throws -> [OKModelResponse.Model] {
        let response = try await ollamaKit.models()
        
        // TODO FIND A PLACE FOR THIS
//        let req = OKPullModelRequestData(name: "mistral:latest")
//        let res = try await ollamaKit.pullModel(data: req)
//        print(res)
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
