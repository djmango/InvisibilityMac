import SwiftData
import SwiftUI

@Observable
final class ChatViewModel: ObservableObject {
    static var shared: ChatViewModel!

    private var modelContext: ModelContext

    var chats: [Chat] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch() throws {
        let sortDescriptor = SortDescriptor(\Chat.modifiedAt, order: .reverse)
        let fetchDescriptor = FetchDescriptor<Chat>(sortBy: [sortDescriptor])

        chats = try modelContext.fetch(fetchDescriptor)
    }

    func create(_ chat: Chat) throws {
        modelContext.insert(chat)
        chats.insert(chat, at: 0)

        try modelContext.saveChanges()
    }

    func rename(_ chat: Chat) throws {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        }

        try modelContext.saveChanges()
    }

    func delete(_ chat: Chat) throws {
        modelContext.delete(chat)
        chats.removeAll(where: { $0.id == chat.id })

        try modelContext.saveChanges()
    }

    func modify(_ chat: Chat) throws {
        chat.modifiedAt = .now

        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: index)
            chats.insert(chat, at: 0)
        }

        try modelContext.saveChanges()
    }

    static func example(modelContainer: ModelContainer, chats _: [Chat]) -> ChatViewModel {
        let example = ChatViewModel(modelContext: ModelContext(modelContainer))
        return example
    }
}
