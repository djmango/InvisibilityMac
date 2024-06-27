import Combine
import Foundation

class MessageActionButtonViewModel: ObservableObject {
    @Published private(set) var isGenerating: Bool = false
    private var message: APIMessage

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = .shared

    init(message: APIMessage) {
        self.message = message

        messageViewModel.$isGenerating
            .receive(on: RunLoop.main)
            .assign(to: \.isGenerating, on: self)
            .store(in: &cancellables)
    }

    func regenerate() {
        Task { @MainActor in
            await messageViewModel.regenerate(message: message)
        }
    }
}
