import Combine
import SwiftUI

class MessageScrollHeaderViewModel: ObservableObject {
    @Published private(set) var messageCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = MessageViewModel.shared
    private let chatViewModel: ChatViewModel = ChatViewModel.shared

    init() {
        messageViewModel.$api_messages
            .sink { [weak self] _ in
                self?.messageCount = self?.messageViewModel.api_messages_in_chat.count ?? 0
            }
            .store(in: &cancellables)

        chatViewModel.$chat
            .sink { [weak self] _ in
                self?.messageCount = self?.messageViewModel.api_messages_in_chat.count ?? 0
            }
            .store(in: &cancellables)
    }
}
