import Glur
import OSLog
import SwiftData
import SwiftUI
import ViewCondition
import ViewState

struct MessageView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var viewState: ViewState? = nil
    @State private var content: String = ""
    @State private var isDragActive: Bool = false

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject var chatViewModel: ChatViewModel = ChatViewModel.shared

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(messageViewModel.messages.indices, id: \.self) { index in
                        let message: Message = messageViewModel.messages.reversed()[index]
                        // Generate the view for the individual message.
                        MessageListItemView(message: message)
                            .generating(message.content == nil && isGenerating)
                            .finalMessage(index == messageViewModel.messages.endIndex - 1)
                            .audio(message.audio)
                            .id(message)
                            .rotationEffect(.degrees(180))
                    }
                }
            }
            // .animation(.snappy, value: messageViewModel.messages)
            // .animation(.snappy, value: messageViewModel.messages.last?.content)
            .rotationEffect(.degrees(180)) // LOL THIS IS AN AWESOME SOLUTION
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)

            // Action Icons
            MessageButtonsView()
                .padding(.top, 5)

            ChatField(text: $content, action: sendAction)
                .focused($promptFocused)
                .onTapGesture {
                    promptFocused = true
                }
                .padding(.top, 5)
                .padding(.bottom, 10)
                .scrollIndicators(.never)
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
    }

    // MARK: - Actions

    private func sendAction() {
        guard messageViewModel.sendViewState == nil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }

        let images = chatViewModel.images.map(\.imageData)

        let message = Message(content: content, role: .user, images: images)
        content = ""
        chatViewModel.images.removeAll()

        Task {
            await messageViewModel.send(message)
        }
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
                        messageViewModel.handleFile(url)
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
