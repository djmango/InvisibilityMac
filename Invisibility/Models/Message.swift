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
    /// Optional list of images stored externally to avoid bloating the database
    @Attribute(.externalStorage) var images: [Data]?
    /// The status of the message generation and processing
    var status: MessageStatus? = MessageStatus.pending
    /// The progress of the message processing this is generic and can be used for any processing, useful for UI
    var progress: Double = 0.0

    /// Summarized chunks, just a list of strings for now, keep it simple
    var summarizedChunks: [String] = []

    init(content: String? = nil, role: MessageRole? = nil, images: [Data]? = nil) {
        self.content = content
        self.role = role
        self.images = images
    }

    @Transient
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "Message")

    /// The full text of the message, including the audio text if it exists
    @Transient var text: String {
        let text = content ?? ""
        // truncate characters
        // let truncNum = 50000
        // if text.count > truncNum {
        //     logger.warning("Truncating message to \(truncNum) characters")
        //     text = String(text.prefix(truncNum))
        // }
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

        if let images = self.images, allow_images {
            // Images, multimodal
            let imageUrls = images.map { VisionContent.ChatCompletionContentPartImageParam.ImageURL(url: $0, detail: .auto) }
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
