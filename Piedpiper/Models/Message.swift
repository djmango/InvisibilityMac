import OllamaKit
import Foundation
import SwiftData

enum Role: String, Codable {
    case system
    case user
    case assistant
}

@Model
final class Message: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    
    var content: String?
    var role: Role?
    var done: Bool = false
    var error: Bool = false
    var createdAt: Date = Date.now
    
    @Relationship var chat: Chat?
        
    init(content: String?, role: Role?) {
        self.content = content
        self.role = role
    }
    
    @Transient var model: String {
        chat?.model?.name ?? ""
    }
}

extension Message {
    func toChatMessage() -> ChatMessage? {
        guard let content = self.content else { return nil }
        guard let role = self.role else { return nil }
        return ChatMessage(role: role.rawValue, content: content)
    }
}

extension Message: CustomStringConvertible {
    var description: String {
        return "\(role?.rawValue ?? ""): \(content ?? "")"
//        return "\(content ?? "")"
    }
}
