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
    @State private var scrollOffset: CGFloat = 0
    @State private var previousContentSize: CGSize = .zero

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    private var windowManager: WindowManager = WindowManager.shared

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                ScrollViewReader { _ in
                    ScrollView {
                        LazyVStack(alignment: .trailing, spacing: 5) {
                            ForEach(messageViewModel.messages.indices, id: \.self) { index in
                                let message: Message = messageViewModel.messages.reversed()[index]
                                // Generate the view for the individual message.
                                MessageListItemView(message: message)
                                    .id(message)
                                    .rotationEffect(.degrees(180))
                                    .sentryTrace("MessageListItemView")
                            }
                        }
                        .background(GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).origin.y)
                                .preference(key: ContentSizePreferenceKey.self, value: geometry.size)
                        })
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                            scrollOffset = offset
                            let prev = isLockedToBottom
                            isLockedToBottom = scrollOffset >= 0
                            if prev != isLockedToBottom {
                                if isLockedToBottom {
                                    logger.debug("Locked to bottom")
                                } else {
                                    logger.debug("Unlocked from bottom")
                                }
                            }
                        }
                        // .onPreferenceChange(ContentSizePreferenceKey.self) { size in
                        //     let previousHeight = previousContentSize.height
                        //     let currentHeight = size.height
                        //     previousContentSize = size
                        //     print("Previous height: \(previousHeight)")

                        //     if !isLockedToBottom {
                        //         let heightDiff = currentHeight - previousHeight
                        //         scrollOffset += heightDiff
                        //         print("Scroll offset: \(scrollOffset)")
                        //         proxy.scrollTo(scrollOffset, anchor: .top)
                        //     }
                        // }
                        // .onChange(of: messageViewModel.isGenerating) {
                        //     logger.debug("Is generating: \(messageViewModel.isGenerating)")
                        //     if messageViewModel.isGenerating {
                        //         scrollToBottom(proxy)
                        //         proxy.
                        //     }
                        // }
                    }
                    .coordinateSpace(name: "scrollView")
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
                    .sentryTrace("ScrollView")
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

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastMessage = messageViewModel.messages.last else {
            return
        }

        // proxy.scrollTo(lastMessage, anchor: .bottom)
        withAnimation(.easeOut(duration: 0.3)) {
            logger.debug("Scrolling to bottom started")
            proxy.scrollTo(lastMessage, anchor: .bottom)
            logger.debug("Scrolling to bottom finished")
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
