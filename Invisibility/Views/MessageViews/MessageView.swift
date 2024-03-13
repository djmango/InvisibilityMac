import OSLog
import SwiftData
import SwiftUI
import ViewCondition

struct MessageView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var content: String = ""
    @State private var isDragActive: Bool = false
    @State private var isResizeHovered: Bool = false
    @State private var offset = CGSize.zero

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject var windowManager: WindowManager = WindowManager.shared

    private var isResizeButtonVisible: Bool {
        // isHovered && isAssistant
        true
    }

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .trailing, spacing: 5) {
                        ForEach(messageViewModel.messages.indices, id: \.self) { index in
                            let message: Message = messageViewModel.messages.reversed()[index]
                            // Generate the view for the individual message.
                            MessageListItemView(message: message)
                                .id(message)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .animation(.snappy, value: messageViewModel.messages.count)
                    .animation(.snappy, value: windowManager.resized)
                    // .animation(.snappy, value: messageViewModel.expansionTotal)
                    // .animation(.easeOut, value: messageViewModel.expansionTotal)
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.005), // Finish fading in
                            .init(color: .black, location: 0.995), // Start fading out
                            .init(color: .clear, location: 1.0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(180)) // LOL THIS IS AN AWESOME SOLUTION
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .padding(.trailing, 40)
                .overlay(
                    // Resize button
                    VStack(alignment: .trailing) {
                        Spacer()
                        HStack {
                            Spacer()
                            MessageButtonItemView(label: "Resize", icon: windowManager.resized ? "arrow.left" : "arrow.right") {
                                resizeAction()
                            }
                        }
                        .visible(if: isResizeButtonVisible, removeCompletely: true)
                        .onHover { hovering in
                            isResizeHovered = hovering
                        }
                        Spacer()
                    }
                    .animation(.snappy, value: isResizeHovered)
                    .padding(8)
                )

                // Action Icons
                MessageButtonsView()
                    .padding(.top, 5)
                    .frame(maxWidth: 400)

                ChatField(text: $content, action: sendAction)
                    .focused($promptFocused)
                    .onTapGesture {
                        promptFocused = true
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .scrollIndicators(.never)
                    .frame(maxWidth: 400)
            }
            .animation(.snappy, value: chatViewModel.textHeight)
            .overlay(
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .opacity(isDragActive ? 1 : 0)
            )
            .border(isDragActive ? Color.blue : Color.clear, width: 5)
            .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                handleDrop(providers: providers)
            }
            .onAppear {
                promptFocused = true
            }
            .onChange(of: chatViewModel.images) {
                promptFocused = true
            }
            .onChange(of: chatViewModel.shouldFocusTextField) {
                if chatViewModel.shouldFocusTextField {
                    promptFocused = true
                    chatViewModel.shouldFocusTextField = false
                }
            }
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

    @MainActor
    private func resizeAction() {
        windowManager.resizeWindow()
    }
}
