import Combine
import Foundation

class SettingsViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "SettingsViewModel")

    @Published private(set) var availableLLMModels: [LLMModel] = []
    @Published private(set) var user: User?

    private var cancellables = Set<AnyCancellable>()
    private let userManager: UserManager = .shared
    private let mainWindowViewModel: MainWindowViewModel = .shared
    private let updaterViewModel: UpdaterViewModel = .shared
    private let llmModelRepository: LLMModelRepository = .shared
    private let onboardingManager: OnboardingManager = .shared
    private let messageViewModel: MessageViewModel = .shared

    init() {
        llmModelRepository.$models
            .receive(on: DispatchQueue.main)
            .sink { [weak self] models in
                self?.availableLLMModels = models
            }
            .store(in: &cancellables)

        userManager.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
    }

    func login() {
        userManager.login()
    }

    @MainActor func startOnboarding() {
        onboardingManager.startOnboarding()
    }

    @MainActor func changeView(to view: mainWindowView) {
        _ = mainWindowViewModel.changeView(to: view)
    }

    func checkForUpdates() {
        updaterViewModel.updater.checkForUpdates()
    }

    func loadDynamicModels() async {
        await llmModelRepository.loadDynamicModels()
    }

    func getExportChatText() -> String {
        let text = messageViewModel.api_messages_in_chat.map { message in
            "\(message.role.rawValue.capitalized): \(message.text)"
        }.joined(separator: "\n")
        return text
    }
}
