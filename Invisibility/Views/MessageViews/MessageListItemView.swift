import CoreGraphics
import MarkdownUI
import Splash
import SwiftData
import SwiftUI
import ViewCondition
import ViewState

struct MessageListItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared

    private var message: Message

    // Message state
    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool {
        messageViewModel.sendViewState == .loading && (message.content?.isEmpty ?? true)
    }

    init(message: Message) {
        self.message = message
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false
    @State private var whoIsHovering: String?

    private var isCopyButtonVisible: Bool {
        isHovered && !isGenerating
    }

    private var isRegenerateButtonVisible: Bool {
        isHovered && isLastMessage
    }

    private var isLastMessage: Bool {
        message.id == messageViewModel.messages.last?.id
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
                    .visible(if: isGenerating, removeCompletely: true)

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

                Markdown(message.text)
                    .textSelection(.enabled)
                    .markdownTheme(.docC)
                    .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                    .hide(if: isGenerating, removeCompletely: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(nsColor: .separatorColor))
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MessageButtonItemView(label: "Regenerate", icon: "arrow.clockwise") {
                        regenerateAction()
                    }
                    .onHover { hovering in
                        if hovering {
                            whoIsHovering = "Regenerate"
                        } else {
                            whoIsHovering = nil
                        }
                    }
                    .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                    MessageButtonItemView(label: "Copy", icon: "doc.on.doc") {
                        copyAction()
                    }
                    .onHover { hovering in
                        if hovering {
                            whoIsHovering = "Copy"
                        } else {
                            whoIsHovering = nil
                        }
                    }
                    .visible(if: isCopyButtonVisible, removeCompletely: true)
                }
                .animation(.snappy, value: whoIsHovering)
            }
            .padding(5)
            .animation(.snappy, value: isHovered)
            .focusable(false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .onHover {
            isHovered = $0
            isCopied = false
        }
    }

    private var theme: Splash.Theme {
        switch self.colorScheme {
        case .dark:
            .sundellsColors(withFont: .init(size: 16))
        default:
            .sunset(withFont: .init(size: 16))
        }
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
            await messageViewModel.regenerate()
        }
    }

    private func deleteAction() {
        messageViewModel.messages.removeAll { $0.id == message.id }
        let context = SharedModelContainer.shared.mainContext
        context.delete(message)
    }
}
