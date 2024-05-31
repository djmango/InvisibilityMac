import CoreGraphics
import Foundation
import OSLog
import PostHog
import SwiftUI

final class MessageViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageViewModel")

    static let shared = MessageViewModel()

    private var chatTask: Task<Void, Error>?

    private var chat: APIChat?
    @Published public var messages: [Message] = [] // TODO: refactor out of this old class
    @Published public var api_chats: [APIChat] = []
    @Published public var api_messages: [APIMessage] = []
    @Published private var api_files: [APIFile] = []
    @Published public var windowHeight: CGFloat = 0
    @Published public var isGenerating: Bool = false

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        try? fetch()
    }

    func fetch() throws {
        Task {
            do {
                let fetched = try await fetchChatsAndMessages()
                DispatchQueue.main.async {
                    self.api_chats = fetched.chats.sorted(by: { $0.created_at < $1.created_at })
                    self.api_messages = fetched.messages.filter { $0.regenerated == false }.sorted(by: { $0.created_at < $1.created_at })
                    self.api_files = fetched.files.sorted(by: { $0.created_at < $1.created_at })

                    let mapped_messages = self.api_messages.map { message in
                        Message.fromAPI(message, files: fetched.files.filter { $0.message_id == message.id })
                    }
                    self.logger.debug("Fetched messages: \(mapped_messages.count)")

                    self.chat = self.api_chats.last
                    self.messages = mapped_messages
                }
            } catch {
                logger.warning("Error fetching data: \(error)")
            }
        }
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

    @MainActor
    func sendFromChat() async {
        guard let chat else {
            logger.error("No chat to send message to")
            return
        }
        guard let user = UserManager.shared.user else {
            logger.error("No user to send message as")
            return
        }

        // Stop the chat from generating if it is
        if isGenerating { stopGenerating() }

        // If the user has exceeded the daily message limit, don't send the message and pop up an alert
        print(UserManager.shared.numMessagesLeft)
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

        let api_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: TextViewModel.shared.text,
            role: "user",
            regenerated: false,
            created_at: Date(),
            updated_at: Date()
        )
        let message = Message(api: api_message, content: TextViewModel.shared.text, role: .user, images: images, hidden_images: hidden_images)
        TextViewModel.shared.clearText()
        ChatViewModel.shared.removeAll()

        await send(message)
        numMessagesSentToday += 1
    }

    @MainActor
    private func send(_ message: Message, regenerate_from_message_id: UUID? = nil) async {
        guard let chat else {
            logger.error("No chat to send message to")
            return
        }
        guard let user = UserManager.shared.user else {
            logger.error("No user to send message as")
            return
        }

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
        let api_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: "",
            role: "assistant",
            regenerated: false,
            created_at: Date(),
            updated_at: Date()
        )
        let assistantMessage = Message(api: api_message, content: nil, role: .assistant)

        messages.append(contentsOf: [message, assistantMessage])

        chatTask = Task {
            let lastMessageId = messages.last?.id
            await LLMManager.shared.chat(
                messages: messages,
                chat: chat,
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
            userMessage.api.id = UUID()
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
    func newChat() {
        defer { PostHogSDK.shared.capture("new_chat") }
        guard let user = UserManager.shared.user else {
            logger.error("User not found")
            return
        }

        self.chat = APIChat(
            id: UUID(),
            user_id: user.id,
            name: "New Chat",
            created_at: Date(),
            updated_at: Date()
        )

        self.api_chats.append(chat!)
        self.messages.removeAll()
    }

    @MainActor
    func switchChat(_ chat: APIChat) {
        defer { PostHogSDK.shared.capture("switch_chat") }
        self.chat = chat
        self.messages = self.api_messages
            .filter { $0.chat_id == chat.id }
            .compactMap { message in
                let files = self.api_files.filter { $0.message_id == message.id }
                return Message.fromAPI(message, files: files)
            }
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
