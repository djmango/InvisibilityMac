import Combine
import Foundation

class HistoryViewModel: ObservableObject {
    static let shared = HistoryViewModel()

    @Published private(set) var groupedChats: [String: [APIChat]] = [:]

    let categoryOrder: [String] = [
        "Today",
        "This Week",
        "Last Week",
        "Last 30 Days",
        "Older",
    ]

    private var cancellables = Set<AnyCancellable>()

    private init() {
        Publishers.CombineLatest(MessageViewModel.shared.$api_chats, MessageViewModel.shared.$api_messages)
            .map { [weak self] chats, messages in
                self?.groupChats(chats: chats, messages: messages) ?? [:]
            }
            .receive(on: RunLoop.main)
            .assign(to: \.groupedChats, on: self)
            .store(in: &cancellables)
    }

    private func groupChats(chats: [APIChat], messages: [APIMessage]) -> [String: [APIChat]] {
        let now = Date()
        var categories: [String: [APIChat]] = Dictionary(uniqueKeysWithValues: categoryOrder.map { ($0, []) })

        let sortedChats = chats.sorted { chat1, chat2 in
            let lastMessageDate1 = lastMessageFor(chat: chat1, in: messages)?.created_at ?? chat1.created_at
            let lastMessageDate2 = lastMessageFor(chat: chat2, in: messages)?.created_at ?? chat2.created_at
            return lastMessageDate1 > lastMessageDate2
        }

        for chat in sortedChats {
            if chat.parent_message_id != nil { continue }

            let chatDate = lastMessageFor(chat: chat, in: messages)?.created_at ?? chat.created_at

            if Calendar.current.isDateInToday(chatDate) {
                categories["Today"]?.append(chat)
            } else if let startOfWeek = now.startOfWeek, chatDate >= startOfWeek, chatDate < now {
                categories["This Week"]?.append(chat)
            } else if let lastWeekStart = now.daysAgo(14).startOfWeek,
                      let thisWeekStart = now.startOfWeek,
                      chatDate >= lastWeekStart, chatDate < thisWeekStart
            {
                categories["Last Week"]?.append(chat)
            } else if chatDate >= now.daysAgo(30), chatDate < now {
                categories["Last 30 Days"]?.append(chat)
            } else {
                categories["Older"]?.append(chat)
            }
        }

        return categories
    }

    private func lastMessageFor(chat: APIChat, in messages: [APIMessage]) -> APIMessage? {
        messages.last { $0.chat_id == chat.id }
    }
}
