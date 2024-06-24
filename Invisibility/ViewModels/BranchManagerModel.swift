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

    private func updateBranchPath(prefixPath: [APIMessage], branchPointId: UUID) {
        var addedMsgs = Set(prefixPath.map { $0.id })
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
        let chatMessages = messages.filter({ $0.chat_id == chat.id })
            .sorted(by: { $0.created_at < $1.created_at })
        
        // Check if this chat has a parent and if the message is the first in the chat
        return chat.parent_message_id != nil && chatMessages.first?.id == message.id
    }
    
    public func moveLeft(message: APIMessage) {
        // get the branchingMessage
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
    public func addNewBranch(rootMsgId: UUID, branch: APIChat) {
        guard let editMsg = editMsg else {
            return
        }
        
        // Find the chat that this message belongs to
        guard let rootMsg = MessageViewModel.shared.api_messages.first(where: { $0.id == rootMsgId }) else {
            return
        }
        
        guard let rootMsgChat = MessageViewModel.shared.api_chats.first(where: { $0.id == rootMsg.chat_id}) else {
            return
        }
        
        if var branchPoint = branchPoints[rootMsgId] {
            branchPoint.branches.append(branch)
            branchPoint.currIdx = branchPoint.currIdx + 1
            branchPoints[rootMsgId] = branchPoint
        } else {
            branchPoints[rootMsgId] = BranchPoint(currIdx: 1, branches: [rootMsgChat, branch])
        }
        // if its a new branch, the formula is:
        let prefixPath = MessageViewModel.shared.api_messages_in_chat.prefix(while: { $0.id != editMsg.id })
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
    
    public func initializeChatBranch(rootChat: APIChat) -> [APIMessage] {
            // use cached messages by chat
            guard let rootMessages = MessageViewModel.shared.messagesByChat[rootChat.id] else {
                print("NO cached messages")
                return []
            }
            var initBranch: [APIMessage] = []
            for msg in rootMessages {
                if msg.role == .user, branchPoints[msg.id] != nil {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    
                    let res = initBranch + constructPostFixPath(branchPointId: msg.id, addedMsgs: Set(initBranch.map { $0.id }))
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let elapsedTime = endTime - startTime
                    
                    print(String(format: "Time taken: %.3f milliseconds", elapsedTime * 1000))
                    
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
            guard let branchPoint = branchPoints[branchPointId] else { return [] }
            
            let currentChat = branchPoint.branches[branchPoint.currIdx]
        
            if blackListChats.contains(currentChat.id) { return [] }
            blackListChats.formUnion(branchPoint.branches.map { $0.id }.filter { $0 != currentChat.id })
            
            // use cached messages
            guard let currentChatMessages = MessageViewModel.shared.messagesByChat[currentChat.id] else { return []}
            
            var postfixPath: [APIMessage] = []
            
            for msg in currentChatMessages where !addedMsgs.contains(msg.id) {
                if msg.role == .user, branchPoints[msg.id] != nil, msg.id != branchPointId {
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
}
