import OllamaKit
import Pow
import SwiftUI
import ViewCondition

struct ChatSidebarListView: View {
    @State private var isRestarting = false

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
                    // .transition(
                    //     .asymmetric(
                    //         insertion: .identity
                    //             .animation(.linear(duration: 1).delay(2))
                    //             .combined(with: .movingParts.anvil),
                    //         removal: .identity
                    //     )
                    // )
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
        .listStyle(.sidebar)
        .task {
            try? ChatViewModel.shared.fetch()
        }
        .toolbar {
            ToolbarItemGroup {
                Spacer()

                Button(action: {
                    isRestarting = true
                    Task {
                        do {
                            try await OllamaKit.shared.waitForAPI(restart: true)
                            isRestarting = false
                        } catch {
                            print(error)
                            // TODO: Show error
                        }
                    }
                }) {
                    Label("Restart Models", systemImage: "arrow.clockwise")
                        .rotationEffect(.degrees(isRestarting ? 360 : 0))
                        .animation(isRestarting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRestarting)
                }
                .help("Restart Models")

                Button("New Chat", systemImage: "square.and.pencil") {
                    CommandViewModel.shared.addChat()
                }
                .buttonStyle(.accessoryBar)
                .help("New Chat (⌘ + N)")
            }
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
        CommandViewModel.shared.selectedChat = nil
    }
}
