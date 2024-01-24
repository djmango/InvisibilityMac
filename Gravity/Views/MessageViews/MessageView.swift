import os
import SwiftData
import SwiftUI
import SwiftUIIntrospect
import ViewCondition
import ViewState

struct MessageView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "MessageView")

    private var chat: Chat

    @Environment(\.modelContext) private var modelContext: ModelContext

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var viewState: ViewState? = nil
    @State private var content: String = ""
    @State private var isDragActive: Bool = false
    @State private var selection: [Message] = []

    init(for chat: Chat) {
        self.chat = chat
    }

    var messageViewModel: MessageViewModel {
        MessageViewModelManager.shared.viewModel(for: chat)
    }

    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            VStack {
                List(messageViewModel.messages.indices, id: \.self) { index in
                    let message: Message = messageViewModel.messages[index]
                    // Generate the action for the message, if it is an assistant message.
                    let action: () -> Void = {
                        regenerateAction(for: message)
                    }

                    // Generate the view for the individual message.
                    MessageListItemView(
                        message: message,
                        regenerateAction: action
                    )
                    .generating(message.content == nil && isGenerating)
                    .finalMessage(index == messageViewModel.messages.endIndex - 1)
                    .error(message.error, message: messageViewModel.sendViewState?.errorMessage)
                    .audioStatus(messageViewModel.audioStatus)
                    .id(message)
                }
                .onAppear {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages) {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: messageViewModel.messages.last?.content) {
                    scrollToBottom(scrollViewProxy)
                }

                HStack(alignment: .center) {
                    ChatField("Message", text: $content, action: sendAction)
                        .textFieldStyle(CapsuleChatFieldStyle())
                        .focused($promptFocused)

                    Button(action: sendAction) {
                        Image(systemName: "paperplane.fill")
                            .padding(8)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Send message")
                    .hide(if: isGenerating, removeCompletely: true)

                    Button(action: messageViewModel.stopGenerate) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generation")
                    .visible(if: isGenerating, removeCompletely: true)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal)
            }
            .overlay(
                // Grey overlay when the user is dragging a file.
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .opacity(isDragActive ? 1 : 0)
            )
            .border(isDragActive ? Color.blue : Color.clear, width: 5)
            .onDrop(of: [.fileURL, .image], isTargeted: $isDragActive) { providers in
                handleDrop(providers: providers)
            }
            .copyable(selection.compactMap(\.content))
            .task {
                initAction()
            }
            .onChange(of: chat) {
                initAction()
            }
        }

        .navigationTitle(chat.name)
    }

    // MARK: - Actions

    private func initAction() {
        try? messageViewModel.fetch(for: chat)

        CommandViewModel.shared.selectedChat = chat

        isEditorFocused = true
    }

    private func sendAction() {
        guard messageViewModel.sendViewState == nil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }

        // If model download is not complete, alert the user.
        guard OllamaViewModel.shared.mistralDownloadStatus == .complete ||
            OllamaViewModel.shared.mistralDownloadStatus == .offline
        else {
            AlertViewModel.shared.alertTitle = AppMessages.modelNotDownloadedTitle
            AlertViewModel.shared.alertMessage = AppMessages.modelNotDownloadedMessage
            AlertViewModel.shared.showAlert = true
            return
        }

        let message = Message(content: content, role: .user, chat: chat)

        Task {
            try ChatViewModel.shared.modify(chat)
            content = ""
            await messageViewModel.send(message)
        }
    }

    private func regenerateAction(for message: Message) {
        message.completed = false

        Task {
            try ChatViewModel.shared.modify(chat)
            await messageViewModel.regenerate(message)
        }
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
            }
            // Handle images (e.g., from screenshot thumbnail)
            else if provider.hasItemConformingToTypeIdentifier("public.png") {
                _ = provider.loadDataRepresentation(for: .image) { data, error in
                    if error == nil, let data {
                        let image = NSImage(data: data)
                        logger.debug("ITWORKED: \(image)")

                        // // Write the image data to a temporary file
                        // do {
                        //     let tmpURL = FileManager.default.temporaryDirectory
                        //         .appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
                        //     try image.write(to: tmpURL)
                        //     logger.debug("Image saved to temporary file: \(tmpURL)")
                        //     messageViewModel.handleFile(url: tmpURL)
                        // } catch {
                        //     logger.error("Error writing image to temporary file: \(error)")
                        // }
                    } else {
                        logger.error("Error loading image: \(error!)")
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
