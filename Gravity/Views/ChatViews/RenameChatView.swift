import SwiftUI
import ViewState

struct RenameChatView: View {
    private var chat: Chat

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String

    init(for chat: Chat) {
        self.chat = chat

        _name = State(initialValue: chat.name)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Name", text: $name)
            }
            .padding()
            .frame(width: 300)
            .navigationTitle("Rename Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: saveAction)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    func saveAction() {
        chat.name = name
        try? ChatViewModel.shared.rename(chat)

        dismiss()
    }
}
