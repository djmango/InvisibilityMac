import Combine
import Foundation
import SwiftUI

struct BranchPoint {
    var currIdx: Int
    var branches: [APIChat]
}

final class BranchManagerModel: ObservableObject {
    static let shared = BranchManagerModel()

    @Published var editMsg: APIMessage? = nil
    public var editText: String = ""
    public var editViewHeight: CGFloat = 40
    public var chatBranchPoints = [UUID: BranchPoint]()
    public var processedChats = Set<UUID>()
    @Published var currentBranchPath = [APIMessage]()

    /// This is a hack to update the text field rendering when the text is cleared
    @Published var clearToggle: Bool = false

    private init() {}

    func clearEdit() {
        self.editMsg = nil
        self.editText = ""
        self.clearToggle.toggle()
    }

    public func getEditParentMsgId(message: APIMessage? = nil) -> UUID? {
        guard let effectiveMessage = message ?? editMsg else {
            return nil
        }
        // Find the chat that this message belongs to
        guard let chat = MessageViewModel.shared.api_chats.first(where: { $0.id == effectiveMessage.chat_id }) else {
            return nil
        }

        if chat.parent_message_id == nil {
            return effectiveMessage.id
        }

        return chat.parent_message_id
    }

    private func updateBranchPath(prefixPath: [APIMessage], branchPointId: UUID) {
        var addedMsgs = Set(prefixPath.map(\.id))
        let postfixPath = constructPostFixPath(branchPointId: branchPointId, addedMsgs: addedMsgs)

        let currentBranchPath = prefixPath + postfixPath

        MessageViewModel.shared.api_messages_in_chat = currentBranchPath
    }

    public func isBranch(message: APIMessage) -> Bool {
        let chats = MessageViewModel.shared.api_chats
        let messages = MessageViewModel.shared.api_messages

        // Check if any chat has this message as its parent
        if chats.contains(where: { $0.parent_message_id == message.id }) {
            return true
        }

        // Find the chat that this message belongs to
        guard let chat = chats.first(where: { $0.id == message.chat_id }) else {
            return false
        }

        // Get all messages for this chat, sorted by creation date
        let chatMessages = messages.filter { $0.chat_id == chat.id }
            .sorted(by: { $0.created_at < $1.created_at })

        // Check if this chat has a parent and if the message is the first in the chat
        return chat.parent_message_id != nil && chatMessages.first?.id == message.id
    }

    public func canMoveLeft(message: APIMessage) -> Bool {
        guard let branchPointId = getEditParentMsgId(message: message) else { return false }
        guard let branchPoint = chatBranchPoints[branchPointId] else { return false }

        if branchPoint.currIdx - 1 >= 0 {
            return true
        }
        return false
    }

    public func canMoveRight(message: APIMessage) -> Bool {
        guard let branchPointId = getEditParentMsgId(message: message) else { return false }
        guard let branchPoint = chatBranchPoints[branchPointId] else { return false }

        if branchPoint.currIdx + 1 < branchPoint.branches.count {
            return true
        }
        return false
    }

    public func moveLeft(message: APIMessage) {
        // get the branchingMessage
        guard let branchPointId = getEditParentMsgId(message: message) else { return }
        guard var branchPoint = chatBranchPoints[branchPointId] else { return }

        if branchPoint.currIdx > 0 {
            branchPoint.currIdx -= 1
            chatBranchPoints[branchPointId] = branchPoint
            let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
            updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        }
    }

    public func moveRight(message: APIMessage) {
        // get the branchingMessage
        guard let branchPointId = getEditParentMsgId(message: message) else { return }
        guard var branchPoint = chatBranchPoints[branchPointId] else { return }

        if branchPoint.currIdx < branchPoint.branches.count - 1 {
            branchPoint.currIdx += 1
            chatBranchPoints[branchPointId] = branchPoint
            let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
            updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        }
    }

    // called when user creates new branchpoint using edit
    public func addNewBranch(rootMsgId: UUID, branch: APIChat) {
        guard let editMsg else {
            return
        }

        // Find the chat that this message belongs to
        guard let rootMsg = MessageViewModel.shared.api_messages.first(where: { $0.id == rootMsgId }) else {
            return
        }

        guard let rootMsgChat = MessageViewModel.shared.api_chats.first(where: { $0.id == rootMsg.chat_id }) else {
            return
        }

        if var branchPoint = chatBranchPoints[rootMsgId] {
            branchPoint.branches.append(branch)
            branchPoint.currIdx = branchPoint.currIdx + 1
            chatBranchPoints[rootMsgId] = branchPoint
        } else {
            chatBranchPoints[rootMsgId] = BranchPoint(currIdx: 1, branches: [rootMsgChat, branch])
        }
        // if its a new branch, the formula is:
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != editMsg.id })
        MessageViewModel.shared.api_messages_in_chat = Array(prefixPath)
    }

    // called after fetch all chats/messages
    public func initializeChatBranchPoints(rootChat: APIChat, messages: [APIMessage], chats: [APIChat]) {
        if processedChats.contains(rootChat.id) {
            return
        }
        processedChats.insert(rootChat.id)
        var chatQueue = [rootChat]
        var addedChats = Set<UUID>() // To avoid processing the same chat multiple times

        while !chatQueue.isEmpty {
            let currentChat = chatQueue.removeFirst()
            addedChats.insert(currentChat.id)

            let chatMessages = messages.filter { $0.chat_id == currentChat.id }

            for message in chatMessages {
                let messageBranches = chats.filter { $0.parent_message_id == message.id }

                if !messageBranches.isEmpty {
                    guard let messageChat = chats.first(where: { $0.id == message.chat_id }) else {
                        continue
                    }
                    chatBranchPoints[message.id] = BranchPoint(currIdx: 0, branches: [messageChat] + messageBranches)

                    // Add unprocessed chats to the queue
                    for branch in messageBranches where !addedChats.contains(branch.id) {
                        chatQueue.append(branch)
                    }
                }
            }
        }
    }

    public func initializeChatBranch(rootChat: APIChat) -> [APIMessage] {
        // use cached messages by chat
        guard let rootMessages = MessageViewModel.shared.messagesByChat[rootChat.id] else {
            return []
        }
        var initBranch: [APIMessage] = []
        for msg in rootMessages {
            if msg.role == .user, chatBranchPoints[msg.id] != nil {
                let res = initBranch + constructPostFixPath(branchPointId: msg.id, addedMsgs: Set(initBranch.map(\.id)))
                return res
            }
            initBranch.append(msg)
        }
        return initBranch
    }

    public func constructPostFixPath(branchPointId: UUID, addedMsgs: Set<UUID>) -> [APIMessage] {
        var addedMsgs = addedMsgs
        var blackListChats = Set<UUID>()

        func constructPath(branchPointId: UUID) -> [APIMessage] {
            guard let branchPoint = chatBranchPoints[branchPointId] else { return [] }

            let currentChat = branchPoint.branches[branchPoint.currIdx]

            if blackListChats.contains(currentChat.id) { return [] }
            blackListChats.formUnion(branchPoint.branches.map(\.id).filter { $0 != currentChat.id })

            // use cached messages
            guard let currentChatMessages = MessageViewModel.shared.messagesByChat[currentChat.id] else { return [] }

            var postfixPath: [APIMessage] = []

            for msg in currentChatMessages where !addedMsgs.contains(msg.id) {
                if msg.role == .user, chatBranchPoints[msg.id] != nil, msg.id != branchPointId {
                    postfixPath.append(contentsOf: constructPath(branchPointId: msg.id))
                    break
                } else {
                    postfixPath.append(msg)
                    addedMsgs.insert(msg.id)
                }
            }

            return postfixPath
        }

        return constructPath(branchPointId: branchPointId)
    }

    public func getRootChat(currentChat: APIChat?, msgs: [APIMessage], chats: [APIChat]) -> APIChat? {
        guard let currentChat else { return nil }
        // base case, currentChat is root chat
        if currentChat.parent_message_id == nil {
            return currentChat
        }
        // get chat of currentChat.parent_message_id
        guard let parentMsg = msgs.first(where: { $0.id == currentChat.parent_message_id }) else {
            return currentChat
        }

        guard let parentChat = chats.first(where: { $0.id == parentMsg.chat_id }) else {
            return currentChat
        }

        return getRootChat(currentChat: parentChat, msgs: msgs, chats: chats)
    }
}
