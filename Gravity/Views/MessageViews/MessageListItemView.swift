import CoreGraphics
import MarkdownUI
import SwiftData
import SwiftUI
import ViewCondition

struct MessageListItemView: View {
    private var message: Message
    private var messageViewModel: MessageViewModel
    let regenerateAction: () -> Void
    let audioAction: () -> Void

    // Message state
    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool = false
    private var isFinalMessage: Bool = false
    private var isError: Bool = false
    private var errorMessage: String? = nil
    private var audio: Audio? = nil

    init(message: Message,
         messageViewModel: MessageViewModel,
         regenerateAction: @escaping () -> Void,
         audioAction: @escaping () -> Void)
    {
        self.message = message
        self.messageViewModel = messageViewModel
        self.regenerateAction = regenerateAction
        self.audioAction = audioAction
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false

    private var isCopyButtonVisible: Bool {
        isHovered && isAssistant && !isGenerating
    }

    private var isDeleteButtonVisible: Bool {
        isHovered && isFinalMessage
    }

    private var isRegenerateButtonVisible: Bool {
        isCopyButtonVisible && isAssistant && isFinalMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? "Gravity" : "You")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.accent)

            ProgressView()
                .controlSize(.small)
                .visible(if: isGenerating && isFinalMessage && message.audio == nil, removeCompletely: true)

            if let errorMessage {
                TextError(errorMessage)
                    .visible(if: isError, removeCompletely: true)
                    .hide(if: isGenerating, removeCompletely: true)
            }

            Markdown(message.content ?? "")
                .textSelection(.enabled)
                .markdownTextStyle(\.text) {
                    FontSize(NSFont.preferredFont(forTextStyle: .title3).pointSize)
                }
                .markdownTextStyle(\.code) {
                    FontFamily(.system(.monospaced))
                }
                .markdownBlockStyle(\.codeBlock) { configuration in
                    configuration
                        .label
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .markdownTextStyle {
                            FontSize(NSFont.preferredFont(forTextStyle: .title3).pointSize)
                            FontFamily(.system(.monospaced))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(nsColor: .separatorColor))
                        }
                        .padding(.bottom)
                }
                .hide(if: isGenerating, removeCompletely: true)
                .hide(if: isError, removeCompletely: true)

            if let audio {
                AudioWidgetView(audio: audio, tapAction: audioAction)
                    .hide(if: isError, removeCompletely: true)
                    .padding(.top, 8)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }

            if let images = message.images {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(images, id: \.self) { imageData in
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                // https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:)
                                .frame(maxWidth: 256, maxHeight: 384) // 2:3 aspect ratio max
                                .cornerRadius(8) // Rounding is strange for large images, seems to be proportional to size for some reason
                                .shadow(radius: 2)
                        }
                    }
                }
            }

            HStack(alignment: .center, spacing: 8) {
                Button(action: copyAction) {
                    Image(systemName: isCopied ? "list.clipboard.fill" : "clipboard")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Copy")
                .visible(if: isCopyButtonVisible, removeCompletely: true)

                Button(action: regenerateAction) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Regenerate")
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)

                Spacer()

                Button(action: deleteAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Delete")
                .visible(if: isDeleteButtonVisible)
            }
            .padding(.top, 8)
            .visible(if: isAssistant || isFinalMessage, removeCompletely: true)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onHover {
            isHovered = $0
            isCopied = false
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

    public func error(_ isError: Bool, message: String?) -> MessageListItemView {
        var view = self
        view.isError = isError
        view.errorMessage = message ?? AppMessages.generalErrorMessage

        return view
    }
}
