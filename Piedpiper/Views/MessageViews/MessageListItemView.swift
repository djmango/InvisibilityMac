import CoreGraphics
import MarkdownUI
import SwiftUI
import ViewCondition

struct MessageListItemView: View {
    @EnvironmentObject private var imageViewModel: ImageViewModel

    private var message: Message
    let regenerateAction: () -> Void

    // Message state
    private var isAssistant: Bool = false
    private var isGenerating: Bool = false
    private var isFinalMessage: Bool = false
    private var isError: Bool = false
    private var errorMessage: String? = nil

    private var geometry: GeometryProxy

    init(message: Message,
         geometry: GeometryProxy,
         regenerateAction: @escaping () -> Void)
    {
        self.message = message
        self.geometry = geometry
        self.regenerateAction = regenerateAction
    }

    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false

    private var isCopyButtonVisible: Bool {
        isHovered && isAssistant && !isGenerating
    }

    private var isRegenerateButtonVisible: Bool {
        isCopyButtonVisible && isAssistant && isFinalMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? "Piedpiper" : "You")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.accent)

            ProgressView()
                .controlSize(.small)
                .visible(if: isGenerating && isFinalMessage, removeCompletely: true)

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

            if let images = message.images {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(images, id: \.self) { imageData in
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                // https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:)
                                .frame(maxWidth: 256, maxHeight: 384) // 2:3 aspect ratio max
                                .onTapGesture {
                                    let frame = geometry.frame(in: .global)
                                    imageViewModel.setImage(image: nsImage, originalFrame: frame)
                                }
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
                .visible(if: isCopyButtonVisible)

                Button(action: regenerateAction) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Regenerate")
                .visible(if: isRegenerateButtonVisible)
            }
            .padding(.top, 8)
            .visible(if: isAssistant, removeCompletely: true)
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
        let content = MarkdownContent(message.content ?? "")
        let plainText = content.renderPlainText()

        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(plainText, forType: .string)

        isCopied = true
    }

    // MARK: - Modifiers

    public func assistant(_ isAssistant: Bool) -> MessageListItemView {
        var view = self
        view.isAssistant = isAssistant

        return view
    }

    public func generating(_ isGenerating: Bool) -> MessageListItemView {
        var view = self
        view.isGenerating = isGenerating

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
