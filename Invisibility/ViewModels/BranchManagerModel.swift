import Foundation
import Combine
import SwiftUI

struct BranchPoint {
    var currIdx: Int
    var branches: [APIChat]
}

final class BranchManagerModel: ObservableObject {
    static let shared = BranchManagerModel()
    
    @Published var editMsg : APIMessage? = nil
    public var editText : String = ""
    public var editViewHeight: CGFloat = 40 
    public var branchPoints: [UUID: BranchPoint] = [:]
    @Published var currentBranchPath: [APIMessage] = []
    
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

    public func messageText(_ id : UUID) {
        let msg = MessageViewModel.shared.api_messages.first(where: {$0.id == id})
        print("msg id: \(id), text: \(msg!.text)")
    }
    
    private func updateBranchPath(prefixPath: [APIMessage], branchPointId : UUID) {
         print("updateBranchPath()")
         let currentBranchPath = prefixPath + constructPostFixPath(branch_message_id: branchPointId)
        print("branchpoint:")
        messageText(branchPointId)
        print("msgs:")
        for msg in currentBranchPath {
            messageText(msg.id)
        }
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
        let chatMessages = messages.filter({ $0.chat_id == chat.id })
            .sorted(by: { $0.created_at < $1.created_at })
        
        // Check if this chat has a parent and if the message is the first in the chat
        return chat.parent_message_id != nil && chatMessages.first?.id == message.id
    }
    
    public func moveLeft(message: APIMessage) {
        // get the branchingMessage
        print("moveLeft")
        guard let branchPointId = getEditParentMsgId(message: message) else {return}
        guard var branchPoint = branchPoints[branchPointId] else { return }
        
        if branchPoint.currIdx > 0 {
            branchPoint.currIdx -= 1
            branchPoints[branchPointId] = branchPoint
            let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
            updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        }
    }
    
    public func moveRight(message: APIMessage) {
        // get the branchingMessage
        print("moveRight")
        guard let branchPointId = getEditParentMsgId(message: message) else {return}
        guard var branchPoint = branchPoints[branchPointId] else { return }
        
        if branchPoint.currIdx < branchPoint.branches.count - 1 {
            branchPoint.currIdx += 1
            branchPoints[branchPointId] = branchPoint
            let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != message.id })
            updateBranchPath(prefixPath: Array(prefixPath), branchPointId: branchPointId)
        }
    }
    
    // called when user creates new branchpoint using edit
    public func addNewBranch(rootMessageId: UUID, branch: APIChat) {
        print("addNewBranch()")
        // Find the chat that this message belongs to
        guard let rootMessage = MessageViewModel.shared.api_messages.first(where: { $0.id == rootMessageId }) else {
            return
        }
        
        guard let rootMessageChat = MessageViewModel.shared.api_chats.first(where: { $0.id == rootMessage.chat_id}) else {
            return
        }
        
        if var branchPoint = branchPoints[rootMessageId] {
            branchPoint.branches.append(branch)
            branchPoint.currIdx = branchPoint.branches.count - 1
            branchPoints[rootMessageId] = branchPoint
        } else {
            branchPoints[rootMessageId] = BranchPoint(currIdx: 0, branches: [rootMessageChat, branch])
        }
        // if its a new branch, the formula is:
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != rootMessageId })
        MessageViewModel.shared.api_messages_in_chat = Array(prefixPath)
    }
   
    // called after fetch all chats/messages
    public func initializeBranchPoints(messages: [APIMessage], chats: [APIChat]) {
        var chatQueue = chats.filter({$0.parent_message_id == nil})
        var processedChats = Set<UUID>()  // To avoid processing the same chat multiple times
      
        while !chatQueue.isEmpty {
          let currentChat = chatQueue.removeFirst()
          processedChats.insert(currentChat.id)
          
          let chatMessages = messages.filter { $0.chat_id == currentChat.id }
          
          for message in chatMessages {
              let messageBranches = chats.filter { $0.parent_message_id == message.id }
              
              if !messageBranches.isEmpty {
                  guard let messageChat = chats.first(where: {$0.id == message.chat_id}) else {
                      continue
                  }
                  branchPoints[message.id] = BranchPoint(currIdx: 0, branches: [messageChat] + messageBranches )
                  
                  // Add unprocessed chats to the queue
                  for branch in messageBranches where !processedChats.contains(branch.id) {
                      chatQueue.append(branch)
                  }
              }
          }
      }
    }
    
    public func initializeChatBranch(rootChat: APIChat, allMessages: [APIMessage]) -> [APIMessage] {
        print("initializeChatBranch")
        let rootMessages = allMessages.filter { $0.chat_id == rootChat.id }
        var chatQueue = [rootChat]
        var initBranch: [APIMessage] = []
        
        while !chatQueue.isEmpty {
            let currentChat = chatQueue.removeFirst()
            // Get all messages in current chat
            let chatMessages = allMessages.filter { $0.chat_id == currentChat.id }
                .sorted { $0.created_at < $1.created_at }  // Ensure messages are in order
            
            for msg in chatMessages {
                initBranch.append(msg)
                if let branchPoint = branchPoints[msg.id] {
                    if branchPoint.currIdx < branchPoint.branches.count {
                        let nextChat = branchPoint.branches[branchPoint.currIdx]
                        chatQueue.append(nextChat)
                    }
                    break
                }
            }
        }
            
            return initBranch
        }
    
    // called whenever rerender of msgs is needed in current chat, so after moveLeft, moveRight,or addNewBranch
    public func constructPostFixPath(branch_message_id: UUID) -> [APIMessage] {
        // Assert message is in branchPoints. If not, add it.
        if branchPoints[branch_message_id] == nil {
            return []
        }
        var addedMsgs = Set<UUID>()
        // Recursively construct postfix path
        func constructPostfixPath(branchPointId: UUID) -> [APIMessage] {
            var postfixPath: [APIMessage] = []
            guard let branchPoint = branchPoints[branchPointId] else { return postfixPath }
            
            // branchPoint.branches is = [originalChat, branchChat1, branchChat2, ...]
            
            let currentChat = branchPoint.branches[branchPoint.currIdx]
            let currentChatMessages = MessageViewModel.shared.api_messages.filter({$0.chat_id == currentChat.id}).filter({$0.regenerated == false}).sorted { $0.created_at < $1.created_at }

            for msg in currentChatMessages where !addedMsgs.contains(msg.id) {
                postfixPath.append(msg)
                addedMsgs.insert(msg.id)
                if msg.role == .user, branchPoints[msg.id] != nil, msg.id != branchPointId {
                    postfixPath.append(contentsOf: constructPostfixPath(branchPointId: msg.id))
                    break
                }
            }
            
            return postfixPath
        }
        
        return constructPostfixPath(branchPointId: branch_message_id)
    }
}
