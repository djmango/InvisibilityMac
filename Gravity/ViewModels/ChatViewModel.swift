import OSLog
import SwiftData
import SwiftUI

@Observable
final class ChatViewModel: ObservableObject {
    let logger = Logger(subsystem: "ai.grav.app", category: "ChatViewModel")

    static var shared = ChatViewModel()

    let modelContext = SharedModelContainer.shared.mainContext

    var chats: [Chat] = []

    private init() {
        do {
            try fetch()
        } catch {
            logger.error("Failed to fetch chats: \(error.localizedDescription)")
        }
    }

    func fetch() throws {
        let sortDescriptor = SortDescriptor(\Chat.modifiedAt, order: .reverse)
        let fetchDescriptor = FetchDescriptor<Chat>(sortBy: [sortDescriptor])

        chats = try modelContext.fetch(fetchDescriptor)
    }

    func create(_ chat: Chat) throws {
        modelContext.insert(chat)
        chats.insert(chat, at: 0)
    }

    func rename(_ chat: Chat) throws {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        }
    }

    func delete(_ chat: Chat) throws {
        // First we have to set the selected chat to the next non-deleted chat
        if CommandViewModel.shared.selectedChat.id == chat.id {
            if let nextChat = chats.first(where: { $0.id != chat.id }) {
                CommandViewModel.shared.selectedChat = nextChat
            } else {
                DispatchQueue.main.async {
                    CommandViewModel.shared.selectedChat = CommandViewModel.shared.addChat()
                }
            }
        }
        modelContext.delete(chat)
        chats.removeAll(where: { $0.id == chat.id })
    }

    func modify(_ chat: Chat) throws {
        chat.modifiedAt = .now

        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: index)
            chats.insert(chat, at: 0)
        }
    }
}
