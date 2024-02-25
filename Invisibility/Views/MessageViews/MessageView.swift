import Glur
import OSLog
import SwiftData
import SwiftUI
import ViewCondition
import ViewState

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var cornerRadius: CGFloat

    func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.layer?.cornerRadius = cornerRadius
    }
}

struct MessageView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageView")

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var viewState: ViewState? = nil
    @State private var content: String = ""
    @State private var isDragActive: Bool = false
    // @State private var selection: [Message] = []

    init() {
        logger.debug("Initializing MessageView")

        isEditorFocused = true
        promptFocused = true
    }

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModelManager.shared.messageViewModel

    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, cornerRadius: 50)
                .blur(radius: 25)

            VStack {
                ScrollViewReader { scrollViewProxy in
                    List(messageViewModel.messages.indices, id: \.self) { index in
                        let message: Message = messageViewModel.messages[index]
                        let action: () -> Void = {
                            regenerateAction(for: message)
                        }

                        let audioActionPassed: () -> Void = {
                            guard let audio = message.audio else { return }
                            audioAction(for: audio)
                        }
                        VStack {
                            if let audio = message.audio {
                                AudioWidgetView(audio: audio, tapAction: audioActionPassed)
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                            } else if let images = message.images {
                                HStack(alignment: .center, spacing: 8) {
                                    ForEach(images, id: \.self) { imageData in
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
                            } else {
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
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(nsColor: .separatorColor))
                        )
                        .padding(.horizontal, -5)
                        .id(message)
                        .listRowSeparator(.hidden)
                    }
                    .scrollContentBackground(.hidden)
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
                    .task {
                        scrollToBottom(scrollViewProxy)
                    }
                }

                ChatField(text: $content, action: sendAction)
                    .focused($promptFocused)
                    .onTapGesture {
                        promptFocused = true
                    }
                // .background(
                //     RoundedRectangle(cornerRadius: 90)
                //         .fill(
                //             RadialGradient(
                //                 gradient: Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)]),
                //                 center: .center,
                //                 startRadius: 0,
                //                 endRadius: 330
                //             )
                //         )
                //         .blur(radius: 10)
                //         .frame(width: 330, height: 180)
                // )

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
            // .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        // RoundedRectangle(cornerRadius: 8)
        //     .fill(LinearGradient(
        //         gradient: Gradient(colors: [Color.white.opacity(0), Color.white.opacity(0.1)]),
        //         startPoint: .top, endPoint: .bottom
        //     ))
        //     .blur(radius: 10)
        // .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        // .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
        // .copyable(selection.compactMap(\.content))
    }

    // MARK: - Actions

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

        logger.debug("Scrolling to bottom")
        logger.debug("Last message: \(lastMessage)")

        proxy.scrollTo(lastMessage, anchor: .bottom)
    }
}
