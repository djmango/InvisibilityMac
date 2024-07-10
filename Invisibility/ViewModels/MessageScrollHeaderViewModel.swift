import Combine
import SwiftUI

class MessageScrollHeaderViewModel: ObservableObject {
    @Published private(set) var messageCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = MessageViewModel.shared
    private let chatViewModel: ChatViewModel = ChatViewModel.shared

    init() {
        Publishers.CombineLatest(chatViewModel.$chat, messageViewModel.$api_messages)
            .sink { [weak self] chat, messages in
                self?.messageCount = messages.filter { $0.chat_id == chat?.id && $0.regenerated == false }.count
            }
            .store(in: &cancellables)
    }
}
