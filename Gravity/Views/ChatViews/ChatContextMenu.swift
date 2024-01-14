import SwiftUI

struct ChatContextMenu: View {
    private var chat: Chat

    init(for chat: Chat) {
        self.chat = chat
    }

    var body: some View {
        Button("Rename \"\(chat.name)\"") {
            CommandViewModel.shared.chatToRename = chat
        }
        .keyboardShortcut("r", modifiers: [.command])

        // Button("Auto-rename \"\(chat.name)\"") {
        //     viewModel.chatToAutorename = chat
        // }

        Divider()

        Button("Delete \"\(chat.name)\"") {
            CommandViewModel.shared.chatToDelete = chat
        }
        .keyboardShortcut(.delete, modifiers: [.shift, .command])
    }
}
