import CoreGraphics
import MarkdownUI
import Splash
import SwiftData
import SwiftUI
import ViewCondition

struct MessageListItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var message: Message
    private let messageViewModel: MessageViewModel = MessageViewModel.shared

    // Message state
    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool = false
    private var isFinalMessage: Bool = false
    private var audio: Audio? = nil

    init(message: Message) {
        self.message = message
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false

    private var isCopyButtonVisible: Bool {
        isHovered && !isGenerating
    }

    var body: some View {
        ZStack {
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
                    .visible(if: isGenerating && isFinalMessage && message.audio == nil, removeCompletely: true)

                if let audio {
                    AudioWidgetView(audio: audio)
                        .padding(.top, 8)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .visible(if: message.audio != nil, removeCompletely: true)
                }

                HStack(alignment: .center, spacing: 8) {
                    ForEach(message.images ?? [], id: \.self) { imageData in
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 256, maxHeight: 384) // 2:3 aspect ratio max
                                .cornerRadius(8) // Rounding is strange for large images, seems to be proportional to size for some reason
                                .shadow(radius: 2)
                        }
                    }
                }
                .visible(if: message.images != nil, removeCompletely: true)

                Markdown(message.content ?? "")
                    .textSelection(.enabled)
                    // .font(.custom("SF Pro Display", size: 16))
                    .markdownTheme(.docC)
                    .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                    // .markdownFont(.custom("SF Pro Display", size: 16))
                    // .markdownTextStyle {
                    //     // Font
                    //     BackgroundColor(nil)
                    // }
                    .hide(if: isGenerating, removeCompletely: true)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("WidgetColor"))
                    .shadow(radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(nsColor: .separatorColor))
                    )
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MessageButtonItemView(label: "Copy", icon: "doc.on.doc") {
                        copyAction()
                    }
                }
            }
            .animation(.snappy, value: isHovered)
            .hide(if: !isCopyButtonVisible, removeCompletely: true)
            .focusable(false)
        }
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

    private func deleteAction() {
        messageViewModel.messages.removeAll { $0.id == message.id }
        let context = SharedModelContainer.shared.mainContext
        context.delete(message)
    }

    // MARK: - Modifiers

    public func generating(_ isGenerating: Bool) -> MessageListItemView {
        var view = self
        view.isGenerating = isGenerating

        return view
    }

    public func audio(_ audio: Audio?) -> MessageListItemView {
        guard let audio else {
            return self
        }
        var view = self
        view.audio = audio

        return view
    }

    public func finalMessage(_ isFinalMessage: Bool) -> MessageListItemView {
        var view = self
        view.isFinalMessage = isFinalMessage

        return view
    }
}
