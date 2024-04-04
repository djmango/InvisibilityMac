import MarkdownWebView
import OSLog
import SentrySwiftUI
import SwiftData
import SwiftUI

struct MessageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false
    @State private var isLockedToBottom: Bool = true
    @State private var offset = CGPoint.zero
    @State private var scrollProxy: ScrollViewProxy?

    private func handleOffset(_ scrollOffset: (CGPoint, CGFloat)) {
        self.offset = scrollOffset.0
        print("Offset: \(scrollOffset.0)")
        print("Offsetf: \(scrollOffset.1)")
    }

    private func header() -> some View {
        Spacer()
    }

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    private var windowManager: WindowManager = WindowManager.shared

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        let _ = Self._printChanges()
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .trailing, spacing: 5) {
                            Rectangle()
                                .frame(height: max(0, messageViewModel.windowHeight - 210))
                                .hidden()

                            ForEach(messageViewModel.messages.indices, id: \.self) { index in
                                let message: Message = messageViewModel.messages[index]
                                // Generate the view for the individual message.
                                MessageListItemView(message: message)
                                    .id(message)
                                    .sentryTrace("MessageListItemView")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .sentryTrace("ScrollView")
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom()
                    }
                    .onChange(of: messageViewModel.messages.count) {
                        scrollToBottom()
                    }
                }

                Spacer()

                // Action Icons
                MessageButtonsView()
                    .sentryTrace("MessageButtonsView")
                    .frame(maxHeight: 40)

                Spacer()

                ChatField(action: sendAction)
                    .focused($promptFocused)
                    .onTapGesture {
                        promptFocused = true
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .scrollIndicators(.never)
                    .sentryTrace("ChatField")
            }
            .animation(AppConfig.snappy, value: chatViewModel.textHeight)
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
        .sentryTrace("MessageView")
    }

    // MARK: - Actions

    private func sendAction() {
        Task { await messageViewModel.sendFromChat() }
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

    private func scrollToBottom() {
        guard let lastMessage = messageViewModel.messages.last else {
            return
        }
        guard let scrollProxy else {
            return
        }

        // proxy.scrollTo(lastMessage, anchor: .bottom)
        withAnimation(.easeOut(duration: 0.3)) {
            logger.debug("Scrolling to bottom started")
            scrollProxy.scrollTo(lastMessage, anchor: .bottom)
            logger.debug("Scrolling to bottom finished")
        }
    }
}
