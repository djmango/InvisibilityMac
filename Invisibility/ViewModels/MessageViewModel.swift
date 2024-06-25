import CoreGraphics
import Foundation
import OSLog
import PostHog
import SwiftUI
import Combine

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
    @Published public var api_messages_in_chat: [APIMessage] = []
    @Published public var messagesByChat :  [UUID: [APIMessage]] = [:]
    private var cancellables = Set<AnyCancellable>()
        
    private func setupChatObserver() {
      ChatViewModel.shared.$chat
          .compactMap { $0 } // Ignore nil values
          .sink { [weak self] newChat in
              print("setupChatObserver triggered, switch root chat")
              self?.updateMessagesForChat(newChat)
          }
        .store(in: &cancellables)
      }
    
   private func updateMessagesForChat(_ chat: APIChat) {
      let rootChat = chat // always
      let branchManager = BranchManagerModel.shared
      
      let initialBranch = branchManager.initializeChatBranch(rootChat: rootChat)
      BranchManagerModel.shared.initializeChatBranchPoints(rootChat: chat, messages: api_messages, chats: api_chats)
      BranchManagerModel.shared.currentBranchPath = initialBranch

      DispatchQueue.main.async {
          self.api_messages_in_chat = initialBranch
          self.shouldScrollToBottom = true
      }
   }
    
    public func messageBranches (message: APIMessage) -> [APIChat] {
        return api_chats.filter { $0.parent_message_id == message.id }
    }

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("token") private var token: String?

    private init() {
        Task {
            await fetchAPI()
        }
        setupChatObserver()
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

            DispatchQueue.main.async { [weak self] in
               guard let self = self else { return }

               let fetched_chats = fetched.chats.sorted { $0.created_at < $1.created_at }
               let fetched_msgs = fetched.messages.filter { !$0.regenerated }.sorted { $0.created_at < $1.created_at }

               self.api_chats = fetched_chats
               self.api_messages = fetched_msgs
               self.api_files = fetched.files.sorted { $0.created_at < $1.created_at }


               if let lastChat = self.api_chats.last,
                  let lastRootChat = BranchManagerModel.shared.getRootChat(currentChat: lastChat, msgs: fetched_msgs, chats: fetched_chats) {
                   
                   if let firstMsg = fetched_msgs.first(where: { $0.chat_id == lastRootChat.id }) {
                       print("First message ID: \(firstMsg.id)")
                       print("First message text: \(firstMsg.text)")
                   } else {
                       print("No messages found for the root chat")
                   }

                   ChatViewModel.shared.chat = lastRootChat

                   self.messagesByChat = Dictionary(grouping: fetched_msgs) { $0.chat_id }
                       .mapValues { messages in
                           messages.filter { !$0.regenerated }.sorted { $0.created_at < $1.created_at }
                       }

                   BranchManagerModel.shared.initializeChatBranchPoints(rootChat: lastRootChat, messages: fetched_msgs, chats: fetched_chats)
               } else {
                   print("No root chat found")
               }
            }
        }

        catch {
            logger.error("Failed to fetch API: \(error)")
        }
    }
   
    // helper
    private func createEditChat(for user: User) -> APIChat? {
        print("createEditChat")
        // get parent msg of currently edited msg
        guard let parentMsgId = BranchManagerModel.shared.getEditParentMsgId() else {
            return nil
        }
        let newChat = APIChat(
            id: UUID(),
            user_id: user.id,
            parent_message_id: parentMsgId
        )
        api_chats.append(newChat)
        BranchManagerModel.shared.addNewBranch(rootMsgId: parentMsgId, branch: newChat)
        return newChat
    }

    @MainActor
    func sendFromChat(editMode : Bool = false) async {
        logger.debug("sendFromChat, editMode: \(editMode)")
        var text = !editMode ? TextViewModel.shared.text : BranchManagerModel.shared.editText
        guard let user = UserManager.shared.user else {
            logger.error("No user to send message as")
            return
        }
       
        // Get or create chat
        var currChat: APIChat?
        if self.chat == nil {
          let newChat = APIChat(
              id: UUID(),
              user_id: user.id
          )
          ChatViewModel.shared.chat = newChat
          api_chats.append(newChat)
              currChat = newChat
        } else if editMode {
           currChat = createEditChat(for: user)
        } else {
           currChat = self.chat
        }

        guard let chat = currChat else {
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
       
        // cleanup
        if editMode {
            BranchManagerModel.shared.clearEdit()
        } else {
            TextViewModel.shared.clearText()
        }
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
            addMessages(messages: [user_message, assistant_message])
            api_messages_in_chat.append(contentsOf: [user_message, assistant_message])
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
            ])
        }

        // Mark only current msg as regenerated
        if let index = api_messages.firstIndex(where: { $0.id == message.id && $0.chat_id == message.chat_id }) {
            api_messages[index].regenerated = true
        }
        
        // assert
        if let index = api_messages_in_chat.firstIndex(where: { $0.id == message.id }) {
            api_messages_in_chat.remove(at: index)
        }
        
        let user_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: user_message_before.text,
            role: .user,
            model_id: LLMManager.shared.model.human_name
        )

        // Copy the images to the new message
        let images = imagesFor(message: user_message_before).map { $0.copyToMessage(message: user_message) }
        api_files.append(contentsOf: images)

        let assistant_message = APIMessage(
            id: UUID(),
            chat_id: chat.id,
            user_id: user.id,
            text: "",
            role: .assistant,
            model_id: LLMManager.shared.model.human_name
        )
        
        api_messages_in_chat.append(contentsOf: [assistant_message])
        addMessages(messages: [assistant_message])

        chatTask = Task {
            let lastMessageId = assistant_message.id
            await LLMManager.shared.chat(
                messages: api_messages,
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
        
    public func addMessages(messages: [APIMessage]) {
        for msg in messages {
            api_messages.append(msg)
            // keep messages grouped by chat up-to-date with additions
            if var chatMessages = messagesByChat[msg.chat_id] {
                /*
               assert(chatMessages.last == nil || msg.created_at > chatMessages.last!.created_at,
                        "New message's creation time must be later than the last message in the chat")
               assert(msg.regenerated != true, "New message should not be marked as regenerated")
                */
               chatMessages.append(msg)
               messagesByChat[msg.chat_id] = chatMessages
           } else {
               messagesByChat[msg.chat_id] = [msg]
           }
        }
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
