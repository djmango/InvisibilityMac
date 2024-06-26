import Combine
import SwiftUI

class HistoryCardViewModel: ObservableObject {
    @Published private(set) var chat: APIChat
    @Published private(set) var isEditing: Bool = false
    @Published var editedName: String = ""

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = .shared
    private let chatViewModel: ChatViewModel = .shared
    private let mainWindowViewModel: MainWindowViewModel = .shared

    init(chat: APIChat) {
        self.chat = chat

        messageViewModel.$api_messages
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func formattedDate(_ date: Date) -> String {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateStyle = .short
        dateTimeFormatter.timeStyle = .short
        return dateTimeFormatter.string(from: date)
    }

    var lastMessageDate: Date {
        messageViewModel.lastMessageWithTextFor(chat: chat)?.created_at ?? chat.created_at
    }

    var lastMessageText: String {
        messageViewModel.lastMessageWithTextFor(chat: chat)?.text ?? ""
    }

    func startEditing() {
        editedName = chat.name != "New Chat" ? chat.name : ""
        isEditing = true
    }

    @MainActor func commitEdit() {
        if !editedName.isEmpty {
            chatViewModel.renameChat(chat, name: editedName)
            chat.name = editedName
        } else {
            editedName = chat.name
        }
        isEditing = false
    }

    @MainActor func deleteChat() {
        chatViewModel.deleteChat(chat)
    }

    @MainActor func switchChat() {
        chatViewModel.switchChat(chat)
        _ = mainWindowViewModel.changeView(to: .chat)
        print("switching to chat cuz view model yk")
    }
}
