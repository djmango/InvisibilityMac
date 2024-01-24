import Foundation
import OllamaKit
import SwiftData

/// Role for message sender, system, user, or assistant
enum Role: String, Codable {
    case system
    case user
    case assistant
}

@Model
final class Message: Identifiable {
    /// Unique identifier for the message
    @Attribute(.unique) var id: UUID = UUID()
    /// Datetime the message was created
    var createdAt: Date = Date.now
    /// Message textual content
    var content: String?
    /// Role for message sender, system, user, or assistant
    var role: Role?
    /// Optional list of images stored externally to avoid bloating the database
    @Attribute(.externalStorage) var images: [Data]? // TODO: refactor this into its own model
    /// Whether the message generation has completed
    var completed: Bool = false
    /// Whether the message generation has errored
    var error: Bool = false
    /// The parent chat of the message
    @Relationship var chat: Chat?
    /// The child audio attached to the message
    @Relationship(deleteRule: .cascade, inverse: \Audio.message) var audio: Audio?

    init(content: String? = nil, role: Role? = nil, chat: Chat? = nil, images: [Data]? = nil) {
        self.content = content
        self.role = role
        self.chat = chat
        self.images = images
    }

    /// The name of the model used to generate the message
    @Transient var model: String {
        chat?.model?.name ?? ""
    }
}

extension Message {
    /// Convert a Message to a ChatMessage for transmission to OlammaKit
    func toChatMessage() -> ChatMessage? {
        guard let content else { return nil }
        guard let role else { return nil }
        let base64Images = images?.compactMap { $0.base64EncodedString() }
        return ChatMessage(role: role.rawValue, content: content, images: base64Images)
    }
}

extension Message: CustomStringConvertible {
    var description: String {
        "\(role?.rawValue ?? ""): \(content ?? "")"
    }
}
