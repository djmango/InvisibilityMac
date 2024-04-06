import SwiftUI

struct MessageListItemView: View {
    private let message: Message

    init(message: Message) {
        self.message = message
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false

    var body: some View {
        let _ = Self._printChanges()
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)

            MessageContent(message: message)

            MessageActionButtonsView(
                message: message,
                isHovered: $isHovered,
                isCopied: $isCopied,
                regenerateAction: regenerateAction,
                copyAction: copyAction
            )
        }
        .onHover {
            if $0 {
                isHovered = true
            } else {
                isHovered = false
            }
            isCopied = false
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 3)
    }

    // MARK: - Actions

    private func copyAction() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(message.content ?? "", forType: .string)

        isCopied = true
    }

    private func regenerateAction() {
        Task {
            await MessageViewModel.shared.regenerate()
        }
    }

    private func markdownText(message: Message) -> String {
        var markdown = ""

        for imageData in message.images {
            let base64String = imageData.base64EncodedString()
            markdown += "![](data:image/png;base64,\(base64String))\n\n"
        }

        markdown += message.text

        return markdown
    }
}
