import SwiftUI
import ViewCondition

struct ChatSidebarListView: View {
    @Environment(CommandViewModel.self) private var commandViewModel

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
        @Bindable var commandViewModelBindable = commandViewModel

        List(selection: $commandViewModelBindable.selectedChat) {
            Section(header: Text("Today")) {
                ForEach(todayChats) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(commandViewModel, for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: todayChats.isEmpty, removeCompletely: true)

            Section(header: Text("Yesterday")) {
                ForEach(yesterdayChats) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(commandViewModel, for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: yesterdayChats.isEmpty, removeCompletely: true)

            Section(header: Text("Previous Days")) {
                ForEach(previousDays) { chat in
                    Label(chat.name, systemImage: "bubble")
                        .contextMenu {
                            ChatContextMenu(commandViewModel, for: chat)
                        }
                        .tag(chat)
                }
            }
            .hide(if: previousDays.isEmpty, removeCompletely: true)
        }
        .listStyle(.sidebar)
        .task {
            try? ChatViewModel.shared.fetch()
        }
        .toolbar {
            ToolbarItemGroup {
                Spacer()

                Button("New Chat", systemImage: "square.and.pencil") {
                    commandViewModel.addChat()
                }
                .buttonStyle(.accessoryBar)
                .help("New Chat (⌘ + N)")
            }
        }
        .sheet(
            isPresented: $commandViewModelBindable.isRenameChatViewPresented
        ) {
            if let chatToRename = commandViewModel.chatToRename {
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
        guard let chatToDelete = commandViewModel.chatToDelete else { return }
        try? ChatViewModel.shared.delete(chatToDelete)

        commandViewModel.chatToDelete = nil
        commandViewModel.selectedChat = nil
    }
}
