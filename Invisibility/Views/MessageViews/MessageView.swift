import OSLog
import ScrollKit
import SentrySwiftUI
import SwiftUI

struct MessageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var isDragActive: Bool = false

    @State private var offset = CGPoint.zero
    @State private var visibleRatio = CGFloat.zero

    func handleOffset(_ scrollOffset: CGPoint, visibleHeaderRatio: CGFloat) {
        self.offset = scrollOffset
        self.visibleRatio = visibleHeaderRatio
    }

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    private var windowManager: WindowManager = WindowManager.shared

    @AppStorage("resized") private var resized: Bool = false

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        // let _ = Self._printChanges()
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                ScrollViewWithStickyHeader(
                    header: { Rectangle().hidden() },
                    // These magic numbers are not perfect, esp the 7 but it works ok for now
                    headerHeight: messageViewModel.messages.count > 7 ? 10 : max(10, messageViewModel.windowHeight - 205),
                    headerMinHeight: 0,
                    onScroll: handleOffset
                ) {
                    VStack(alignment: .trailing, spacing: 5) {
                        ForEach(messageViewModel.messages) { message in
                            // Generate the view for the individual message.
                            MessageListItemView(message: message)
                                .id(message.id)
                                .sentryTrace("MessageListItemView")
                        }
                    }
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
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .defaultScrollAnchor(.bottom)
                .sentryTrace("ScrollView")

                Spacer()

                // Action Icons
                ChatButtonsView()
                    .sentryTrace("ChatButtonsView")
                    .frame(maxHeight: 40)

                Spacer()

                ChatField(action: sendAction)
                    .focused($promptFocused)
                    .onTapGesture {
                        promptFocused = true
                    }
                    .padding(.bottom, 10)
                    .scrollIndicators(.never)
                    .sentryTrace("ChatField")
            }
            .animation(AppConfig.snappy, value: chatViewModel.textHeight)
            .animation(AppConfig.snappy, value: chatViewModel.images)
            .animation(AppConfig.snappy, value: resized)
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
}
