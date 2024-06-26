import Foundation
import Combine
import SwiftUI

final class BranchManagerModel: ObservableObject {
    static let shared = BranchManagerModel()
    
    @Published var editMsg: APIMessage? = nil
    public var editText: String = ""
    @Published var editViewHeight: CGFloat = 40

    /// This is a hack to update the text field rendering when the text is cleared
    @Published var clearToggle: Bool = false
    
    private init() {}
    
    // Reusable function to get branches for a given branch point ID
    private func getBranches(for branchPointId: UUID) -> [APIChat] {
        return MessageViewModel.shared.api_chats.filter { $0.parent_message_id == branchPointId }
    }
    
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
        var addedMsgs = Set(prefixPath.map { $0.id })
        let postfixPath = constructPostFixPath(branchPointId: branchPointId, addedMsgs: addedMsgs)
        
        let currentBranchPath = prefixPath + postfixPath
        
        MessageViewModel.shared.api_messages_in_chat = currentBranchPath
    }
    
    public func isBranch(message: APIMessage) -> Bool {
        // Check if any chat has this message as its parent
        if !getBranches(for: message.id).isEmpty {
            return true
        }
        return false
    }
    
    public func canMoveLeft(message: APIMessage) -> Bool {
        guard let branchPointId = getEditParentMsgId(message: message) else { return false }
        let branches = getBranches(for: branchPointId)
        let currIdx = branches.firstIndex(where: { $0.id == message.chat_id }) ?? -1
        return currIdx > 0
    }
    
    public func canMoveRight(message: APIMessage) -> Bool {
        guard let branchPointId = getEditParentMsgId(message: message) else { return false }
        let branches = getBranches(for: branchPointId)
        let currIdx = branches.firstIndex(where: { $0.id == message.chat_id }) ?? -1
        return currIdx < branches.count - 1 && currIdx != -1
    }
    
    public func getCurrBranchIdx(message: APIMessage) -> Int {
        guard let branchPointId = getEditParentMsgId(message: message) else { return -1 }
        let branches = getBranches(for: branchPointId)
        return branches.firstIndex(where: { $0.id == message.chat_id }) ?? -1
    }
    
    public func getTotalBranches(message: APIMessage) -> Int {
        guard let branchPointId = getEditParentMsgId(message: message) else { return -1 }
        return getBranches(for: branchPointId).count
    }
    
    public func moveLeft(message: APIMessage) {
        print("moveLeft")
        guard let branchPointId = getEditParentMsgId(message: message) else { return }
        let branches = getBranches(for: branchPointId)
        guard let currIdx = branches.firstIndex(where: { $0.id == message.chat_id }), currIdx > 0 else { return }
        
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
        updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        print("done")
    }
    
    public func moveRight(message: APIMessage) {
        print("moveRight")
        guard let branchPointId = getEditParentMsgId(message: message) else { return }
        let branches = getBranches(for: branchPointId)
        guard let currIdx = branches.firstIndex(where: { $0.id == message.chat_id }), currIdx < branches.count - 1 else { return }
        
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
        updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        print("done")
    }
    
    // called when user creates new branchpoint using edit
    public func addNewBranch(rootMsgId: UUID, branch: APIChat) {
        guard let editMsg = editMsg else { return }
        
        // Find the chat that this message belongs to
        guard let rootMsg = MessageViewModel.shared.api_messages.first(where: { $0.id == rootMsgId }) else { return }
        
        guard let rootMsgChat = MessageViewModel.shared.api_chats.first(where: { $0.id == rootMsg.chat_id}) else { return }
        
        // Update the branches
        MessageViewModel.shared.api_chats.append(branch)
        
        // if its a new branch, the formula is:
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != editMsg.id })
        MessageViewModel.shared.api_messages_in_chat = Array(prefixPath)
    }
   
    public func initializeChatBranch(rootChat: APIChat) -> [APIMessage] {
        // Get all messages for this chat
        let rootMessages = MessageViewModel.shared.api_messages.filter { $0.chat_id == rootChat.id }
        var initBranch: [APIMessage] = []
        for msg in rootMessages {
            if msg.role == .user, !getBranches(for: msg.id).isEmpty {
                let res = initBranch + constructPostFixPath(branchPointId: msg.id, addedMsgs: Set(initBranch.map { $0.id }))
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
            let branches = getBranches(for: branchPointId)
            guard !branches.isEmpty else { return [] }
            
            let currentChat = branches[0]  // Assuming we want the first branch
        
            if blackListChats.contains(currentChat.id) { return [] }
            blackListChats.formUnion(branches.map { $0.id }.filter { $0 != currentChat.id })
            
            // Get all messages for this chat
            let currentChatMessages = MessageViewModel.shared.api_messages.filter { $0.chat_id == currentChat.id }
            
            var postfixPath: [APIMessage] = []
            
            for msg in currentChatMessages where !addedMsgs.contains(msg.id) {
                if msg.role == .user, !getBranches(for: msg.id).isEmpty, msg.id != branchPointId {
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
        guard let currentChat = currentChat else { return nil }
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
