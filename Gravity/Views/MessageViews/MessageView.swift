import OSLog
import SwiftData
import SwiftUI
import ViewCondition
import ViewState

struct MessageView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var viewState: ViewState? = nil
    @State private var content: String = ""
    @State private var isDragActive: Bool = false
    @State private var selection: [Message] = []

    init() {}

    let messageViewModel: MessageViewModel = MessageViewModelManager.shared.messageViewModel

    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            VStack {
                Spacer()

                List(messageViewModel.messages.indices, id: \.self) { index in
                    let message: Message = messageViewModel.messages[index]
                    let action: () -> Void = {
                        regenerateAction(for: message)
                    }
                    let audioActionPassed: () -> Void = {
                        guard let audio = message.audio else { return }
                        audioAction(for: audio)
                    }

                    // Generate the view for the individual message.
                    MessageListItemView(
                        message: message,
                        messageViewModel: messageViewModel,
                        regenerateAction: action,
                        audioAction: audioActionPassed
                    )
                    .generating(message.content == nil && isGenerating)
                    .finalMessage(index == messageViewModel.messages.endIndex - 1)
                    .audio(message.audio)
                    .id(message)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                // Disable the scroll bar
                .scrollIndicators(.never)
                .onAppear {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages) {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages.last?.content) {
                    scrollToBottom(scrollViewProxy)
                }

                ChatField("Message", text: $content, action: sendAction)
                    .padding()
                    .textFieldStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("WidgetColor"))
                            .shadow(radius: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(nsColor: .separatorColor))
                            )
                    )
                    .focused($promptFocused)
                    .padding(.horizontal, 10)

                Spacer()
            }
            .overlay(
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .opacity(isDragActive ? 1 : 0)
            )
            .border(isDragActive ? Color.blue : Color.clear, width: 5)
            .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                handleDrop(providers: providers)
            }
            .copyable(selection.compactMap(\.content))
            .task {
                initAction()
                scrollToBottom(scrollViewProxy)
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func initAction() {
        try? messageViewModel.fetch()

        isEditorFocused = true
        promptFocused = true
    }

    private func sendAction() {
        guard messageViewModel.sendViewState == nil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }

        let message = Message(content: content, role: .user)
        content = ""

        Task {
            await messageViewModel.send(message)
        }
    }

    private func regenerateAction(for message: Message) {
        Task {
            await messageViewModel.regenerate(message)
        }
    }

    @MainActor
    private func audioAction(for audio: Audio) {
        AudioPlayerViewModel.shared.audio = audio
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        logger.debug("Handling drop")
        logger.debug("Providers: \(providers)")
        for provider in providers {
            logger.debug("Provider: \(provider.description)")
            logger.debug("Provider types: \(provider.registeredTypeIdentifiers)")
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil else {
                        logger.error("Error loading the dropped item: \(error!)")
                        return
                    }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        // Process the file URL
                        logger.debug("File URL: \(url)")
                        messageViewModel.handleFile(url: url)
                    }
                }
            } else {
                logger.error("Unsupported item provider type")
            }
        }
        return true
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard messageViewModel.messages.count > 0 else { return }
        let lastIndex = messageViewModel.messages.count - 1
        let lastMessage = messageViewModel.messages[lastIndex]

        proxy.scrollTo(lastMessage, anchor: .bottom)
    }
}
