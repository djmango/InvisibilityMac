import SwiftUI

struct ChatContextMenu: View {
    private var chat: Chat

    init(for chat: Chat) {
        self.chat = chat
    }

    var body: some View {
        Button("Rename") {
            CommandViewModel.shared.chatToRename = chat
        }
        .keyboardShortcut("r", modifiers: [.command])

        Button("Auto-rename") {
            Task {
                await MessageViewModelManager.shared.viewModel(for: chat).autorename()
            }
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])

        Divider()

        Button("Delete") {
            CommandViewModel.shared.chatToDelete = chat
        }
        .keyboardShortcut(.delete, modifiers: [.shift, .command])
    }

    private func truncateString(_ string: String, toLength length: Int) -> String {
        String(string.prefix(length))
    }
}
