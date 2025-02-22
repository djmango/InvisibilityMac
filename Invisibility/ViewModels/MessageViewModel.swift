import CoreGraphics
import Foundation
import OSLog
import PostHog
import SwiftUI

final class MessageViewModel: ObservableObject {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MessageViewModel")

    static let shared = MessageViewModel()

    private let userManager: UserManager = .shared

    private var chatTask: Task<Void, Error>?

    private var chat: APIChat? {
        ChatViewModel.shared.chat
    }

    @Published public var api_chats: [APIChat] = []
    @Published public var api_messages: [APIMessage] = []
    @Published public var api_files: [APIFile] = []
    @Published public var api_memories: [APIMemory] = []
    @Published public var windowHeight: CGFloat = 0
    @Published public var isGenerating: Bool = false
    @Published public var shouldScrollToBottom: Bool = false
    @Published private(set) var isLoading: Bool = false

    private let messagePageSize = 50
    private var currentPage = 1
    private let backgroundQueue = DispatchQueue(label: "com.invisibility.messageProcessing", qos: .userInitiated)

    public var api_messages_in_chat: [APIMessage] {
        api_messages.filter { $0.chat_id == ChatViewModel.shared.chat?.id && $0.regenerated == false }
    }

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        Task {
            await fetchAPI()
        }
    }

    public func fetchAPISync() { Task { await fetchAPI() } }

    public func fetchAPI() async {
        let url = URL(string: AppConfig.invisibility_api_base + "/sync/all")!

        guard let token else {
            logger.warning("No token for fetch")
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = iso8601Decoder()
            
            // Process data in background
            try await withCheckedThrowingContinuation { continuation in
                backgroundQueue.async {
                    do {
                        let fetched = try decoder.decode(APISyncResponse.self, from: data)
                        
                        // Process messages in chunks
                        let sortedMessages = fetched.messages
                            .filter { $0.regenerated == false }
                            .sorted(by: { $0.created_at < $1.created_at })
                        
                        let sortedChats = fetched.chats.sorted(by: { $0.created_at < $1.created_at })
                        let sortedFiles = fetched.files.sorted(by: { $0.created_at < $1.created_at })
                        let sortedMemories = fetched.memories.sorted(by: { $0.created_at < $1.created_at })
                        
                        DispatchQueue.main.async {
                            self.api_chats = sortedChats
                            self.api_messages = sortedMessages
                            self.api_files = sortedFiles
                            self.api_memories = sortedMemories
                            self.logger.debug("Fetched messages: \(sortedMessages.count)")
                            ChatViewModel.shared.switchChat(sortedChats.last)
                            continuation.resume()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.logger.error("Failed to process API response: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } catch {
            logger.error("Failed to fetch API: \(error)")
        }
    }

    @MainActor
    func sendFromChat() async {
        var text = ChatWebInputViewModel.shared.text
        guard let user = userManager.user else {
            logger.error("No user to send message as")
            return
        }
        // Get or create chat
        if self.chat == nil {
            let chat = APIChat(
                id: UUID(),
                user_id: user.id
            )
            ChatViewModel.shared.switchChat(chat)
            api_chats.append(chat)
        }
        guard let chat else {
            logger.error("No chat to send message to")
            return
        }

        _ = MainWindowViewModel.shared.changeView(to: .chat)

        logger.debug("Can send messages: \(userManager.canSendMessages)")
        logger.debug("Messages left: \(userManager.numMessagesLeft)")

        // If the user has exceeded the daily message limit, don't send the message and pop up an alert
        if !(userManager.canSendMessages) {
            ToastViewModel.shared.showToast(
                title: "Daily message limit reached"
            )
            return
        }

        // Stop the chat from generating if it is
        if isGenerating { stopGenerating() }

        // If we are streaming video, add the current frame to the images
        if ScreenRecorder.shared.isRunning {
            if let image = ScreenRecorder.shared.getCurrentFrameAsCGImage(),
               let standardizedImage = standardizeImage(image)
            {
                ChatFieldViewModel.shared.addImage(standardizedImage, hide: true)
                logger.info("Added current frame to images")
            } else {
                logger.error("Failed to standardize image.")
            }
        }

        // Allow empty messages if there is a least 1 image or fileContent
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 ||
            ChatFieldViewModel.shared.images.count > 0 ||
            !ChatFieldViewModel.shared.fileContent.isEmpty
        else {
            logger.warning("Empty message")
            return
        }

        // Prepend the fileContent if necessary
        if !ChatFieldViewModel.shared.fileContent.isEmpty {
            text = ChatFieldViewModel.shared.fileContent + "\n" + text
        }

        // when sending, model_id can be nil here because
        // LLMManager manages setting it
        let user_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: text,
            role: .user,
            model_id: LLMManager.shared.model.human_name
        )

        let assistant_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: "",
            role: .assistant,
            model_id: LLMManager.shared.model.human_name
        )

        let images = ChatFieldViewModel.shared.images.map { $0.toAPI(message: user_message) }

        api_files.append(contentsOf: images)

        ChatWebInputViewModel.shared.clearText()
        ChatFieldViewModel.shared.removeAll()

        isGenerating = true
        defer { PostHogSDK.shared.capture(
            "send_message",
            properties: [
                "num_images": imagesFor(message: user_message).count,
                "message_length": user_message.text.count,
                "model": LLMManager.shared.model.human_name,
            ]
        )
        }

        api_messages.append(contentsOf: [user_message, assistant_message])

        chatTask = Task {
            let lastMessageId = assistant_message.id
            await LLMManager.shared.chat(
                messages: api_messages_in_chat,
                chat: chat,
                processOutput: processOutput
            )
            chatComplete(chat: chat, lastMessageId: lastMessageId)
        }

        UserManager.shared.incrementMessagesSentToday()
    }

    @MainActor
    func chatComplete(chat: APIChat, lastMessageId: UUID) {
        logger.debug("Chat complete")
        if api_messages_in_chat.last?.id == lastMessageId {
            // Only update isGenerating if the last message is the chat we are responsible for
            isGenerating = false
        }

        // PUT request to autorename if the chat is named New Chat
        if chat.name == "New Chat" {
            logger.debug("Chat named New Chat, autorenaming")
            Task {
                let url = URL(string: AppConfig.invisibility_api_base + "/chats/\(chat.id)/autorename")!
                guard let token else {
                    logger.warning("No token for autorename")
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                let (data, _) = try await URLSession.shared.data(for: request)

                // logger.debug(String(data: data, encoding: .utf8) ?? "No data")
                let decoder = iso8601Decoder()

                let new_chat = try decoder.decode(APIChat.self, from: data)
                print(new_chat)

                DispatchQueue.main.async {
                    if let index = self.api_chats.firstIndex(of: chat) {
                        self.api_chats[index].name = new_chat.name
                    }
                    print(new_chat.name)
                }
            }
        }
    }

    @MainActor
    func regenerate(message: APIMessage) async {
        guard let chat = self.chat else {
            logger.error("No chat to regenerate")
            return
        }
        guard let user = userManager.user else {
            logger.error("No user to regenerate as")
            return
        }
        // Get the user message before the message to be regenerated
        guard let user_message_before = api_messages_in_chat.last(where: { $0.created_at < message.created_at && $0.role == .user }) else {
            logger.error("No user message before message to regenerate")
            return
        }

        if api_messages_in_chat.count < 2 {
            logger.error("Not enough messages to regenerate")
            return
        }

        isGenerating = true

        defer { PostHogSDK.shared.capture(
            "regenerate_message",
            properties: [
                "num_images": imagesFor(message: message).count,
                "message_length": message.text.count,
                "model": LLMManager.shared.model.human_name,
            ]
        )
        }

        // Mark all messges after the message to be regenerated as regenerated
        for index in api_messages.indices where
            api_messages[index].chat_id == message.chat_id &&
            api_messages[index].created_at >= user_message_before.created_at
        {
            api_messages[index].regenerated = true
        }

        let user_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: user_message_before.text,
            role: .user
        )

        // Copy the images to the new message
        let images = imagesFor(message: user_message_before).map { $0.copyToMessage(message: user_message) }
        api_files.append(contentsOf: images)

        let assistant_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: "",
            role: .assistant
        )

        api_messages.append(contentsOf: [user_message, assistant_message])

        chatTask = Task {
            let lastMessageId = assistant_message.id
            await LLMManager.shared.chat(
                messages: api_messages_in_chat,
                chat: chat,
                processOutput: processOutput,
                regenerate_from_message_id: user_message_before.id
            )
            chatComplete(chat: chat, lastMessageId: lastMessageId)
        }
    }

    @MainActor
    func stopGenerating() {
        logger.debug("Stopping generation")
        defer {
            PostHogSDK.shared.capture(
                "stop_generating",
                properties: ["stopped_message_length": api_messages.last?.text.count ?? 0]
            )
        }
        isGenerating = false
        chatTask?.cancel()
    }

    @MainActor
    func clearAll() {
        api_chats = []
        api_messages = []
        api_files = []
    }

    private func processOutput(output: String, message: APIMessage) {
        DispatchQueue.main.async {
            message.text.append(output)
        }
    }

    func filesFor(message: APIMessage) -> [APIFile] {
        api_files.filter { $0.message_id == message.id }
    }

    func imagesFor(message: APIMessage) -> [APIFile] {
        filesFor(message: message).filter { $0.filetype == .jpeg }
    }

    func shownImagesFor(message: APIMessage) -> [APIFile] {
        filesFor(message: message).filter { $0.filetype == .jpeg && $0.show_to_user == true }
    }

    func lastMessageWithTextFor(chat: APIChat) -> APIMessage? {
        api_messages.filter { $0.chat_id == chat.id }.filter { $0.text.count > 0 }.last
    }
    
    func firstMessageWithTextFor(chat: APIChat) -> APIMessage? {
        api_messages.filter { $0.chat_id == chat.id }.filter { $0.text.count > 0 }.first
    }
    
}
