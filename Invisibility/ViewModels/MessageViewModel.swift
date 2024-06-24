import CoreGraphics
import Foundation
import OSLog
import PostHog
import SwiftUI

final class MessageViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "MessageViewModel")

    static let shared = MessageViewModel()

    private var chatTask: Task<Void, Error>?

    private var chat: APIChat? {
        ChatViewModel.shared.chat
    }

    @Published public var api_chats: [APIChat] = []
    @Published public var api_messages: [APIMessage] = []
    @Published public var api_files: [APIFile] = []
    @Published public var windowHeight: CGFloat = 0
    @Published public var isGenerating: Bool = false
    @Published public var shouldScrollToBottom: Bool = false

    public var api_messages_in_chat: [APIMessage] {
        api_messages.filter { $0.chat_id == ChatViewModel.shared.chat?.id }.filter { $0.regenerated == false }
    }

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        Task {
            await fetchAPI()
        }
    }

    func fetchAPI() async {
        let url = URL(string: AppConfig.invisibility_api_base + "/sync/all")!

        guard let token else {
            logger.warning("No token for fetch")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            // logger.debug(String(data: data, encoding: .utf8) ?? "No data")
            let decoder = iso8601Decoder()

            let fetched = try decoder.decode(APISyncResponse.self, from: data)

            DispatchQueue.main.async {
                self.api_chats = fetched.chats.sorted(by: { $0.created_at < $1.created_at })
                self.api_messages = fetched.messages.filter { $0.regenerated == false }.sorted(by: { $0.created_at < $1.created_at })
                self.api_files = fetched.files.sorted(by: { $0.created_at < $1.created_at })
                self.logger.debug("Fetched messages: \(self.api_messages.count)")
                ChatViewModel.shared.chat = self.api_chats.last
            }
        }

        catch {
            logger.error("Failed to fetch API: \(error)")
        }
    }

    @MainActor
    func sendFromChat() async {
        var text = TextViewModel.shared.text
        guard let user = UserManager.shared.user else {
            logger.error("No user to send message as")
            return
        }
        // Get or create chat
        if self.chat == nil {
            let chat = APIChat(
                id: UUID(),
                user_id: user.id
            )
            ChatViewModel.shared.chat = chat
            api_chats.append(chat)
        }
        guard let chat else {
            logger.error("No chat to send message to")
            return
        }

        _ = MainWindowViewModel.shared.changeView(to: .chat)
        
        logger.debug("Can send messages: \(UserManager.shared.canSendMessages)")
        logger.debug("Messages left: \(UserManager.shared.numMessagesLeft)")
     

        // If the user has exceeded the daily message limit, don't send the message and pop up an alert
        if !(UserManager.shared.canSendMessages) {
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
                ChatViewModel.shared.addImage(standardizedImage, hide: true)
                logger.info("Added current frame to images")
            } else {
                logger.error("Failed to standardize image.")
            }
        }

        // Allow empty messages if there is a least 1 image or fileContent
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 ||
            ChatViewModel.shared.images.count > 0 ||
            !ChatViewModel.shared.fileContent.isEmpty
        else {
            logger.warning("Empty message")
            return
        }

        // Prepend the fileContent if necessary
        if !ChatViewModel.shared.fileContent.isEmpty {
            text = ChatViewModel.shared.fileContent + "\n" + text
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

        let images = ChatViewModel.shared.images.map { $0.toAPI(message: user_message) }

        api_files.append(contentsOf: images)

        TextViewModel.shared.clearText()
        ChatViewModel.shared.removeAll()

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

        withAnimation(AppConfig.snappy) {
            api_messages.append(contentsOf: [user_message, assistant_message])
        }

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
            self.isGenerating = false
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
        guard let user = UserManager.shared.user else {
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

    func lastMessageFor(chat: APIChat) -> APIMessage? {
        api_messages.filter { $0.chat_id == chat.id }.last
    }

    func lastMessageWithTextFor(chat: APIChat) -> APIMessage? {
        api_messages.filter { $0.chat_id == chat.id }.last { $0.text.count > 0 }
    }

    func sortedChatsByLastMessage() -> [APIChat] {
        api_chats.sorted { chat1, chat2 in
            let lastMessageDate1 = lastMessageFor(chat: chat1)?.created_at ?? Date.now
            let lastMessageDate2 = lastMessageFor(chat: chat2)?.created_at ?? Date.now
            return lastMessageDate1 > lastMessageDate2
        }
    }
}
