import Combine
import SwiftUI

class HistoryCardViewModel: ObservableObject {
    @Published private(set) var chat: APIChat
    @Published private(set) var isEditing: Bool = false
    @Published private(set) var isRenaming: Bool = false
    @Published var editedName: String

    private var cancellables = Set<AnyCancellable>()

    private let messageViewModel: MessageViewModel = .shared
    private let chatViewModel: ChatViewModel = .shared
    private let mainWindowViewModel: MainWindowViewModel = .shared

    init(chat: APIChat) {
        self.chat = chat
        self.editedName = chat.name

        messageViewModel.$api_messages
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        $editedName
            .sink { [weak self] _ in
                // If name is not chat.name, we are editing
                self?.isEditing = self?.editedName != self?.chat.name
            }
            .store(in: &cancellables)
    }

    var lastMessageDate: Date {
        messageViewModel.lastMessageWithTextFor(chat: chat)?.created_at ?? chat.created_at
    }

    var lastMessageText: String {
        messageViewModel.lastMessageWithTextFor(chat: chat)?.text ?? ""
    }

    func commitEdit() {
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
        if !editedName.isEmpty {
            DispatchQueue.main.async { self.chatViewModel.renameChat(self.chat, name: self.editedName) }
            chat.name = editedName
            isEditing = false
        } else {
            editedName = chat.name
        }
    }

    func autoRename() {
        Task {
            // Call the autoRename async method and await its result
            self.isRenaming = true
            let newName = await self.chatViewModel.autoRename(self.chat, body: self.lastMessageText)
            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.isRenaming = false
                self.chat.name = newName
                self.editedName = newName
                self.isEditing = false
            }
        }
    }

    @MainActor
    func cancelEdit() {
        isEditing = false
        editedName = chat.name
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    }

    func deleteChat() {
        DispatchQueue.main.async { self.chatViewModel.deleteChat(self.chat) }
    }

    @MainActor func switchChat() {
        chatViewModel.switchChat(chat)
        _ = mainWindowViewModel.changeView(to: .chat)
    }
}
