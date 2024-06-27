import SwiftUI

struct HeaderView: View {
    @StateObject private var viewModel: MessageScrollHeaderViewModel = MessageScrollHeaderViewModel()

    @Binding var numMessagesDisplayed: Int
    @State private var whoIsHovering: String?

    var body: some View {
        HStack {
            MessageButtonItemView(
                label: "Collapse",
                icon: "chevron.down",
                shortcut_hint: "⌘ + ⇧ + U",
                whoIsHovering: $whoIsHovering,
                action: {
                    withAnimation(AppConfig.snappy) {
                        numMessagesDisplayed = 10
                    }
                }
            )
            .visible(if: numMessagesDisplayed > 10, removeCompletely: true)
            .keyboardShortcut("u", modifiers: [.command, .shift])

            MessageButtonItemView(
                label: "Show +\(min(viewModel.messageCount - numMessagesDisplayed, 10))",
                icon: "chevron.up",
                shortcut_hint: "⌘ + ⇧ + I",
                whoIsHovering: $whoIsHovering,
                action: {
                    withAnimation(AppConfig.snappy) {
                        numMessagesDisplayed = min(viewModel.messageCount, numMessagesDisplayed + 10)
                    }
                }
            )
            .visible(if: viewModel.messageCount > 10 && numMessagesDisplayed < viewModel.messageCount, removeCompletely: true)
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
        .animation(AppConfig.snappy, value: numMessagesDisplayed)
    }
}
