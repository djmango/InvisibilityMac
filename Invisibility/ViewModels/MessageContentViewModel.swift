import Combine
import SwiftUI

class MessageContentViewModel: ObservableObject {
    @Published private(set) var message: APIMessage

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = .shared

    var isGenerating: Bool {
        messageViewModel.isGenerating && message.text.isEmpty
    }

    var isLastMessage: Bool {
        message.id == messageViewModel.api_messages.last?.id
    }

    var showLoading: Bool {
        isGenerating && isLastMessage
    }

    var images: [APIFile] {
        messageViewModel.shownImagesFor(message: message)
    }

    init(message: APIMessage) {
        self.message = message

        messageViewModel.api_messages.first(where: { $0.id == message.id })?.$text
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
