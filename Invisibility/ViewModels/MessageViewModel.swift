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

    public var api_messages_in_chat: [APIMessage] {
        api_messages.filter { $0.chat_id == ChatViewModel.shared.chat?.id }.filter { $0.regenerated == false }
    }

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        Task {
            do {
                let fetched = try await fetchAPI()
                DispatchQueue.main.async {
                    self.api_chats = fetched.chats.sorted(by: { $0.created_at < $1.created_at })
                    self.api_messages = fetched.messages.filter { $0.regenerated == false }.sorted(by: { $0.created_at < $1.created_at })
                    self.api_files = fetched.files.sorted(by: { $0.created_at < $1.created_at })
                    self.logger.debug("Fetched messages: \(self.api_messages.count)")
                    ChatViewModel.shared.chat = self.api_chats.last
                }
            } catch {
                logger.warning("Error fetching data: \(error)")
            }
        }
    }

    func fetchAPI() async throws -> APIChatsAndMessagesResponse {
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

        // Allow empty messages if there is a least 1 image
        guard TextViewModel.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 || ChatViewModel.shared.images.count > 0 else { return }

        let user_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: TextViewModel.shared.text,
            role: .user
        )

        let assistant_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: "",
            role: .assistant
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

        api_messages.append(contentsOf: [user_message, assistant_message])

        chatTask = Task {
            let lastMessageId = assistant_message.id
            await LLMManager.shared.chat(
                messages: api_messages_in_chat,
                chat: chat,
                processOutput: processOutput
            )

            await MainActor.run {
                if api_messages_in_chat.last?.id == lastMessageId {
                    // Only update isGenerating if the last message is the chat we are responsible for
                    self.isGenerating = false
                }
            }
            logger.debug("Chat complete")
        }

        numMessagesSentToday += 1
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

            await MainActor.run {
                if api_messages.last?.id == lastMessageId {
                    // Only update isGenerating if the last message is the chat we are responsible for
                    self.isGenerating = false
                }
            }
            logger.debug("Regenerate complete")
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

    func sortedChatsByLastMessage() -> [APIChat] {
        api_chats.sorted { chat1, chat2 in
            let lastMessageDate1 = lastMessageFor(chat: chat1)?.created_at ?? Date.distantPast
            let lastMessageDate2 = lastMessageFor(chat: chat2)?.created_at ?? Date.distantPast
            return lastMessageDate1 > lastMessageDate2
        }
    }
}
