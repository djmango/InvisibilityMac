import Foundation
import SwiftData

/// Role for message sender, system, user, or assistant
enum MessageRole: String, Codable {
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
    var role: MessageRole?
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

    init(content: String? = nil, role: MessageRole? = nil, chat: Chat? = nil, images: [Data]? = nil) {
        self.content = content
        self.role = role
        self.chat = chat
        self.images = images
    }

    /// The name of the model used to generate the message
    @Transient var model: String {
        chat?.model ?? ""
    }

    /// The full text of the message, including the audio text if it exists
    @Transient var text: String {
        var text = content ?? ""
        if let audio {
            text += audio.text
        }
        return text
    }
}

extension Message: CustomStringConvertible {
    var description: String {
        "\(role?.rawValue ?? ""): \(text)"
    }
}
