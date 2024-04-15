import Foundation
import OpenAI
import OSLog
import SwiftData
import SwiftUI

// Alias for ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent(images: images)
typealias VisionContent = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent

/// Role for message sender, system, user, or assistant
enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

/// Status for message generation and processing
enum MessageStatus: String, Codable {
    case pending
    case chat_generation
    case audio_generation
    case chunk_summary_generation
    case email_generation
    case complete
    case error

    var description: String {
        switch self {
        case .pending:
            "Pending"
        case .chat_generation:
            "Chatting"
        case .audio_generation:
            "Transcribing Audio"
        case .chunk_summary_generation:
            "Summarizing"
        case .email_generation:
            "Drafting Email"
        case .complete:
            "Complete"
        case .error:
            "Error"
        }
    }
}

@Model
final class Message: Identifiable, ObservableObject {
    /// Unique identifier for the message
    @Attribute(.unique) var id: UUID = UUID()
    /// Datetime the message was created
    var createdAt: Date = Date.now
    /// Message textual content
    var content: String?
    /// Role for message sender, system, user, or assistant
    var role: MessageRole?
    /// List of images data stored externally to avoid bloating the database
    @Attribute(.externalStorage) var images_data: [Data] = []
    /// List of files data stored externally to avoid bloating the database. PDFs, etc.
    @Attribute(.externalStorage) var files_data: [Data] = []
    /// The status of the message generation and processing
    // TODO: for chat buttons, instead of subscribing to message view use this plus a query
    var status: MessageStatus? = MessageStatus.pending
    /// The progress of the message processing this is generic and can be used for any processing, useful for UI
    var progress: Double = 0.0

    init(content: String? = nil, role: MessageRole? = nil, images: [Data] = []) {
        self.content = content
        self.role = role
        self.images_data = images
    }

    @Transient
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "Message")

    /// The full text of the message, including the audio text if it exists
    @Transient var text: String {
        let text = content ?? ""
        return text
    }
}

extension Message {
    func toChat(allow_images: Bool = false) -> ChatQuery.ChatCompletionMessageParam? {
        var role: ChatQuery.ChatCompletionMessageParam.Role = .user
        if self.role == .assistant {
            role = .assistant
        } else if self.role == .system {
            role = .system
        }

        if allow_images, !images_data.isEmpty {
            // Images, multimodal
            let imageUrls = images_data.map { VisionContent.ChatCompletionContentPartImageParam.ImageURL(url: $0, detail: .auto) }
            let imageParams = imageUrls.map { VisionContent.ChatCompletionContentPartImageParam(imageUrl: $0) }
            let visionContent = imageParams.map { VisionContent(chatCompletionContentPartImageParam: $0) }

            let textParam = VisionContent.ChatCompletionContentPartTextParam(text: self.text)
            let textVisionContent = VisionContent(chatCompletionContentPartTextParam: textParam)

            let content = [textVisionContent] + visionContent

            return ChatQuery.ChatCompletionMessageParam(role: role, content: content)
        } else {
            // Pure text
            return ChatQuery.ChatCompletionMessageParam(role: role, content: text)
        }
    }
}

extension Message: CustomStringConvertible {
    var description: String {
        "\(role?.rawValue ?? ""): \(text)"
    }
}
