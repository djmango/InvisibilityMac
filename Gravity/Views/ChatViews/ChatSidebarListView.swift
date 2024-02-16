import Pow
import SwiftUI
import ViewCondition

struct ChatSidebarListView: View {
    @ObservedObject private var tabViewModel = TabViewModel.shared

    private var todayChats: [Chat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return ChatViewModel.shared.chats.filter {
            calendar.isDate($0.modifiedAt, inSameDayAs: today)
        }
    }

    private var yesterdayChats: [Chat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return ChatViewModel.shared.chats.filter {
            calendar.isDate($0.modifiedAt, inSameDayAs: yesterday)
        }
    }

    private var previousDays: [Chat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return ChatViewModel.shared.chats.filter {
            !calendar.isDate($0.modifiedAt, inSameDayAs: today)
                && !calendar.isDate($0.modifiedAt, inSameDayAs: yesterday)
        }
    }

    var body: some View {
        @Bindable var commandViewModelBindable = CommandViewModel.shared

        List(selection: $commandViewModelBindable.selectedChat) {
            Section(header: Text("Today")) {
                ForEach(todayChats) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: todayChats.isEmpty, removeCompletely: true)

            Section(header: Text("Yesterday")) {
                ForEach(yesterdayChats) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: yesterdayChats.isEmpty, removeCompletely: true)

            Section(header: Text("Previous Days")) {
                ForEach(previousDays) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: previousDays.isEmpty, removeCompletely: true)
        }
        // .frame(width: 260)
        .listStyle(.sidebar)
        .task {
            try? ChatViewModel.shared.fetch()
        }
        .sheet(
            isPresented: $commandViewModelBindable.isRenameChatViewPresented
        ) {
            if let chatToRename = CommandViewModel.shared.chatToRename {
                RenameChatView(for: chatToRename)
            }
        }
        .confirmationDialog(
            AppMessages.chatDeletionTitle,
            isPresented: $commandViewModelBindable.isDeleteChatConfirmationPresented
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteAction)
        } message: {
            Text(AppMessages.chatDeletionMessage)
        }
        .dialogSeverity(.critical)
    }

    // MARK: - Actions

    func deleteAction() {
        guard let chatToDelete = CommandViewModel.shared.chatToDelete else { return }
        try? ChatViewModel.shared.delete(chatToDelete)

        CommandViewModel.shared.chatToDelete = nil
        CommandViewModel.shared.selectedChat = CommandViewModel.shared.selectedChat
    }
}
