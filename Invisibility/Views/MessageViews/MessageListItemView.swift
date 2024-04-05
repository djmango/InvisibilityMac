import CoreGraphics
import MarkdownWebView
import OSLog
import SwiftData
import SwiftUI
import ViewCondition

struct MessageListItemView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageListItemView")

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    private let message: Message

    @AppStorage("shortcutHints") private var shortcutHints = true

    // Message state
    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool { MessageViewModel.shared.isGenerating && (message.content?.isEmpty ?? true) }

    init(message: Message) {
        self.message = message
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false
    @State private var whoIsHovering: String?

    private var isResizeButtonVisible: Bool {
        isHovered && isAssistant
    }

    private var isCopyButtonVisible: Bool {
        (isHovered && !isGenerating) || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command))
    }

    private var isRegenerateButtonVisible: Bool {
        (isHovered && isLastMessage) || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command) && isLastMessage)
    }

    private var isLastMessage: Bool {
        message.id == MessageViewModel.shared.messages.last?.id
    }

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 8) {
                Text(isAssistant ? "Invisibility" : "You")
                    .font(.custom("SF Pro Display", size: 13))
                    .fontWeight(.bold)
                    .tracking(-0.01)
                    .lineSpacing(10)
                    .opacity(0)
                    .overlay(LinearGradient(
                        gradient: isAssistant ?
                            Gradient(colors: [Color("InvisGrad1"), Color("InvisGrad2")]) :
                            Gradient(colors: [Color("YouText"), Color("YouText")]),
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .mask(
                        Text(isAssistant ? "Invisibility" : "You")
                            .font(.custom("SF Pro Display", size: 13))
                            .fontWeight(.bold)
                            .tracking(-0.01)
                            .lineSpacing(10)
                    )

                ProgressView()
                    .controlSize(.small)
                    .visible(if: isGenerating && isLastMessage, removeCompletely: true)

                HStack(alignment: .center, spacing: 8) {
                    ForEach(message.images ?? [], id: \.self) { imageData in
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 256, maxHeight: 384) // 2:3 aspect ratio max
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                    }
                }
                .visible(if: message.images != nil, removeCompletely: true)

                MarkdownWebView(message.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            // Message action buttons
            VStack(alignment: .trailing) {
                Spacer()

                // Regenerate and copy button
                HStack {
                    Spacer()
                    MessageButtonItemView(
                        label: "Regenerate",
                        icon: "arrow.clockwise",
                        shortcut_hint: "⌘ ⇧ R",
                        whoIsHovering: $whoIsHovering
                    ) {
                        regenerateAction()
                    }
                    .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                    .keyboardShortcut("r", modifiers: [.command, .shift])

                    MessageButtonItemView(
                        label: "Copy",
                        icon: isCopied ? "checkmark" : "square.on.square",
                        shortcut_hint: "⌘ ⌥ C",
                        whoIsHovering: $whoIsHovering
                    ) {
                        copyAction()
                    }
                    .keyboardShortcut("c", modifiers: [.command, .option])
                    .changeEffect(.jump(height: 10), value: isCopied)
                    .visible(if: isCopyButtonVisible, removeCompletely: true)
                }
            }
            .animation(AppConfig.snappy, value: whoIsHovering)
            // .animation(AppConfig.snappy, value: isHovered) ?? FOR SOME REASON THIS CAUSES THE FREEZE
            .animation(AppConfig.snappy, value: isHovered)
            .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
            .padding(8)
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
}
