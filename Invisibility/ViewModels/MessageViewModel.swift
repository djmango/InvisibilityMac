import CoreGraphics
import Foundation
import OSLog
import PDFKit
import PostHog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

final class MessageViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageViewModel")

    static let shared = MessageViewModel()

    private let modelContext = SharedModelContainer.shared.mainContext

    private var chatTask: Task<Void, Error>?

    /// The list of messages in the chat
    @Published public var messages: [Message] = []

    /// Whether the chat is currently generating
    @Published public var isGenerating: Bool = false {
        didSet {
            logger.debug("Generating: \(isGenerating)")
        }
    }

    /// The height of the chat window
    @Published public var windowHeight: CGFloat = 0

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0

    private init() {
        try? fetch()
    }

    func fetch() throws {
        let sortDescriptor = SortDescriptor(\Message.createdAt)
        let fetchDescriptor = FetchDescriptor<Message>(
            sortBy: [sortDescriptor]
        )

        let fetched = try modelContext.fetch(fetchDescriptor)
        DispatchQueue.main.async {
            self.messages = fetched
        }
        logger.debug("Fetched \(self.messages.count) messages")
    }

    @MainActor
    func sendFromChat() async {
        // Stop the chat from generating if it is
        if isGenerating { stopGenerating() }

        // If the user has exceeded the daily message limit, don't send the message and pop up an alert
        if !UserManager.shared.canSendMessages {
            ToastViewModel.shared.showToast(
                title: "Daily message limit reached"
            )
            return
        }

        // If we are streaming video, add the current frame to the images
        if ScreenRecorder.shared.isRunning {
            if let image = ScreenRecorder.shared.getCurrentFrameAsCGImage(),
               let standardizedImage = standardizeImage(image)
            {
                ChatViewModel.shared.addImage(standardizedImage, hide: true)
                logger.info("Added current frame to images")
            } else {
                logger.error("Failed to standardize image.")
            }
        }

        let images = ChatViewModel.shared.images.map(\.data)

        // Allow empty messages if there is a least 1 image
        guard TextViewModel.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 || images.count > 0 else { return }

        // Get indices of images that are marked as hidden
        let hidden_images = ChatViewModel.shared.images.enumerated().filter { _, image in
            image.hide
        }.map { index, _ in
            index
        }

        let message = Message(content: TextViewModel.shared.text, role: .user, images: images, hidden_images: hidden_images)
        TextViewModel.shared.clearText()
        ChatViewModel.shared.removeAll()

        await send(message)
        numMessagesSentToday += 1
    }

    @MainActor
    private func send(_ message: Message) async {
        isGenerating = true
        defer { PostHogSDK.shared.capture(
            "send_message",
            properties: [
                "num_images": message.images_data.count,
                "message_length": message.content?.count ?? 0,
                "model": LLMManager.shared.model.human_name,
            ]
        )
        }
        let assistantMessage = Message(content: nil, role: .assistant)

        messages.append(contentsOf: [message, assistantMessage])
        modelContext.insert(message)
        modelContext.insert(assistantMessage)

        chatTask = Task {
            let lastMessageId = messages.last?.id
            await LLMManager.shared.chat(messages: messages, processOutput: processOutput)

            assistantMessage.status = .complete
            await MainActor.run {
                if let lastMessageId, messages.last?.id == lastMessageId {
                    // Only update isGenerating if the last message is the chat we are responsible for
                    self.isGenerating = false
                }
            }
            logger.debug("Chat complete")
        }
    }

    @MainActor
    func regenerate() async {
        isGenerating = true
        defer { PostHogSDK.shared.capture(
            "regenerate_message",
            properties: [
                "num_images": messages.last?.images_data.count ?? 0,
                "message_length": messages.last?.content?.count ?? 0,
                "model": LLMManager.shared.model.human_name,
            ]
        )
        }

        // For easy code reuse, essentially what we're doing here is resetting the state to before the message we want to regenerate was generated
        // So for that, we'll recreate the original send scenario, when the new user message was sent
        // We'll delete it the last two messages, the user message and the assistant message we want to regenerate
        // This assumes chat structure is always user -> assistant -> user

        if messages.count < 2 {
            logger.error("Not enough messages to regenerate")
            return
        }

        // Remove the assistant message we are regenerating from class and ModelContext
        if let assistantMessage = messages.popLast() {
            modelContext.delete(assistantMessage)
        }

        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            await send(userMessage)
        }
    }

    @MainActor
    func deleteMessage(id: UUID) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            modelContext.delete(messages[index])
            _ = withAnimation {
                messages.remove(at: index)
            }
        }
    }

    @MainActor
    func clearChat() {
        defer { PostHogSDK.shared.capture(
            "clear_chat",
            properties: ["message_count": messages.count]
        ) }
        for message in messages {
            modelContext.delete(message)
        }
        self.messages.removeAll()
    }

    @MainActor
    func stopGenerating() {
        logger.debug("Stopping generation")
        defer {
            PostHogSDK.shared.capture(
                "stop_generating",
                properties: ["stopped_message_length": messages.last?.content?.count ?? 0]
            )
        }
        isGenerating = false
        chatTask?.cancel()
    }

    private func processOutput(output: String, message: Message) {
        DispatchQueue.main.async {
            if message.content == nil { message.content = "" }
            message.content?.append(output)
        }
    }
}

// @MARK File Handler
extension MessageViewModel {
    /// Public function that can be called to begin the file open process
    func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        // Define allowed content types using UTType
        openPanel.allowedContentTypes = [
            UTType.image,
        ]

        // Technically doesn't work for the following types:
        // SVGs: Our image standardization function doesn't support SVGs
        // TODO: fix the above issues

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                self.handleFile(url)
            }
        }

        PostHogSDK.shared.capture("open_file")
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        // logger.debug("Handling drop")
        // logger.debug("Providers: \(providers)")
        for provider in providers {
            // logger.debug("Provider: \(provider.description)")
            // logger.debug("Provider types: \(provider.registeredTypeIdentifiers)")
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil else {
                        self.logger.error("Error loading the dropped item: \(error!)")
                        return
                    }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        // Process the file URL
                        // self.logger.debug("File URL: \(url)")
                        self.handleFile(url)
                    }
                }
            } else {
                logger.error("Unsupported item provider type")
            }
        }
        return true
    }

    /// Public function that handles file via a URL regarding a message
    public func handleFile(_ url: URL) {
        defer {
            PostHogSDK.shared.capture("handle_file")
        }
        // First determine if we are dealing with an image or audio file
        logger.debug("Selected file \(url)")
        if let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            // Check if it's an image type
            if fileType.conforms(to: .image) {
                logger.debug("Selected file \(url) is an image.")
                handleImage(url: url)
            } else if fileType.conforms(to: .pdf) {
                logger.debug("Selected file \(url) is a PDF.")
                handlePDF(url: url)
            } else if fileType.conforms(to: .text) {
                logger.debug("Selected file \(url) is a text file.")
                handleText(url: url)
            } else {
                logger.error("Selected file \(url) is of an unknown type.")
                ToastViewModel.shared.showToast(
                    title: "Unknown file type"
                )
            }
        }
    }

    private func handleImage(url: URL) {
        defer { PostHogSDK.shared.capture("handle_image") }
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            logger.error("Failed to create image source from url.")
            return
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            logger.error("Failed to create image from image source.")
            return
        }

        // Standardize and convert the image to a base64 string and store it in the view model
        guard let standardizedImage = standardizeImage(cgImage) else {
            logger.error("Failed to standardize image.")
            return
        }

        DispatchQueue.main.async {
            ChatViewModel.shared.addImage(standardizedImage)
        }
    }

    private func handlePDF(url: URL) {
        defer { PostHogSDK.shared.capture("handle_pdf") }
        guard let pdf = PDFDocument(url: url) else {
            logger.error("Failed to read PDF data from url.")
            return
        }

        guard let data = pdf.dataRepresentation() else {
            logger.error("Failed to get data representation from PDF.")
            return
        }

        var complete_text = ""

        // Insert PDF attributedString if available
        if let pdf = PDFDocument(url: url) {
            let pageCount = pdf.pageCount
            let documentContent = NSMutableAttributedString()

            for i in 0 ..< pageCount {
                guard let page = pdf.page(at: i) else { continue }
                guard let pageContent = page.attributedString else { continue }
                documentContent.append(pageContent)
            }

            complete_text += documentContent.string
        }

        DispatchQueue.main.async {
            TextViewModel.shared.text += complete_text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func handleText(url: URL) {
        defer { PostHogSDK.shared.capture("handle_text") }
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to read text data from url.")
            return
        }

        guard let text = String(data: data, encoding: .utf8) else {
            logger.error("Failed to convert text data to string.")
            return
        }

        DispatchQueue.main.async {
            TextViewModel.shared.text += text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
