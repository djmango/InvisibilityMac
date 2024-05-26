import CoreGraphics
import Foundation
import OSLog
import PDFKit
import PostHog
import SwiftUI
import UniformTypeIdentifiers

// Define a struct for Chat
struct APIChat: Codable {
    let id: UUID
    let user_id: String
    let name: String
    let created_at: Date
    let updated_at: Date
}

// Define a struct for Message
struct APIMessage: Codable {
    let id: UUID
    let chat_id: UUID
    let user_id: String
    let text: String
    let role: String
    let regenerated: Bool
    let created_at: Date
    let updated_at: Date
}

/// Filetype representation, ensures lowercase coding keys
enum APIFiletype: String, Codable, Equatable, CustomStringConvertible {
    case jpeg
    case pdf
    case mp4
    case mp3

    /// Conforms to `CustomStringConvertible` for debugging output.
    var description: String {
        self.rawValue
    }
}

/// File representation with necessary properties and codable conformance
struct APIFile: Codable, Equatable {
    let id: UUID
    let chat_id: UUID
    let user_id: String
    let message_id: UUID
    let filetype: APIFiletype
    let show_to_user: Bool
    let url: String?
    let created_at: Date
    let updated_at: Date
}

// Define a struct for the response
struct APIChatsAndMessagesResponse: Codable {
    let chats: [APIChat]
    let messages: [APIMessage]
    let files: [APIFile]
}

final class MessageViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageViewModel")

    static let shared = MessageViewModel()

    private var chatTask: Task<Void, Error>?

    /// The list of messages in the chat
    @Published public var messages: [Message] = []
    @Published public var chat: APIChat?
    public var api_chats: [APIChat] = []
    public var api_messages: [APIMessage] = []
    public var api_files: [APIFile] = []

    /// Whether the chat is currently generating
    @Published public var isGenerating: Bool = false {
        didSet {
            logger.debug("Generating: \(isGenerating)")
        }
    }

    /// The height of the chat window
    @Published public var windowHeight: CGFloat = 0

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        try? fetch()
    }

    func fetchChatsAndMessages() async throws -> APIChatsAndMessagesResponse {
        guard let url = URL(string: AppConfig.invisibility_api_base + "/sync/all") else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: nil)
        }
        guard let token else {
            logger.warning("No token for fetch")
            throw NSError(domain: "NoToken", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        // logger.debug(String(data: data, encoding: .utf8) ?? "No data")

        let decoder = iso8601Decoder()

        let response = try decoder.decode(APIChatsAndMessagesResponse.self, from: data)

        return response
    }

    func fetch() throws {
        Task {
            do {
                let fetched = try await fetchChatsAndMessages()
                self.api_chats = fetched.chats.sorted(by: { $0.created_at < $1.created_at })
                self.api_messages = fetched.messages.filter { $0.regenerated == false }.sorted(by: { $0.created_at < $1.created_at })
                self.api_files = fetched.files.sorted(by: { $0.created_at < $1.created_at })

                let mapped_messages = self.api_messages.map { message in
                    Message.fromAPI(message, files: fetched.files.filter { $0.message_id == message.id })
                }
                logger.debug("Fetched messages: \(mapped_messages.count)")

                DispatchQueue.main.async {
                    self.chat = self.api_chats.last
                    withAnimation {
                        self.messages = mapped_messages
                    }
                }
            } catch {
                logger.warning("Error fetching data: \(error)")
            }
        }
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
    private func send(_ message: Message, regenerate_from_message_id: UUID? = nil) async {
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

        chatTask = Task {
            let lastMessageId = messages.last?.id
            await LLMManager.shared.chat(
                messages: messages,
                processOutput: processOutput,
                regenerate_from_message_id: regenerate_from_message_id
            )

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

        // Remove the assistant message we are regenerating from class
        messages.removeLast()

        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            // New uuid4 for the user message
            let regenerate_from_message_id = userMessage.id
            userMessage.id = UUID()
            await send(userMessage, regenerate_from_message_id: regenerate_from_message_id)
        }
    }

    @MainActor
    func deleteMessage(id: UUID) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
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
