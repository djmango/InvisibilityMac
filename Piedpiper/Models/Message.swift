import OllamaKit
import Foundation
import SwiftData

/// Role for message sender, system, user, or assistant
enum Role: String, Codable {
    case system
    case user
    case assistant
}

@Model
final class Message: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    
    /// Message textual content
    var content: String?
    /// Role for message sender, system, user, or assistant
    var role: Role?
    /// Optional list of base64 encoded image
    var images: [String]?
    
    var done: Bool = false
    var error: Bool = false
    var createdAt: Date = Date.now
    
    @Relationship var chat: Chat?
        
    init(content: String? = nil, role: Role? = nil, chat: Chat? = nil, images: [String]? = nil) {
        self.content = content
        self.role = role
        self.chat = chat
        self.images = images
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
    }
}
