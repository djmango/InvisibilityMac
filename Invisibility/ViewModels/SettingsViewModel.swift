import Combine
import Foundation

class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "SettingsViewModel")

    @Published private(set) var availableLLMModels: [LLMModel] = []
    @Published private(set) var user: User?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Subscribe to LLMModelRepository changes
        LLMModelRepository.shared.$models
            .receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                self?.availableLLMModels = models
            }
            .store(in: &cancellables)

        // Subscribe to UserManager changes
        UserManager.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
    }
}
