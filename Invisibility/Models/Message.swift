import Foundation
import OpenAI
import OSLog
import PDFKit
import SwiftUI

// Alias for ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent(images: images)
typealias VisionContent = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent

/// Role for message sender, system, user, or assistant
enum MessageRole: String, Codable {
    case system
    case user
    case assistant

    static func fromString(_ rawValue: String) -> MessageRole {
        switch rawValue {
        case "user":
            .user
        case "system":
            .system
        case "assistant":
            .assistant
        default:
            .user
        }
    }
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

final class Message: Identifiable, ObservableObject {
    /// Unique identifier for the message
    var id: UUID = UUID()
    /// Datetime the message was created
    var createdAt: Date = Date.now
    /// Message textual content
    @Published var content: String?
    /// Role for message sender, system, user, or assistant
    var role: MessageRole?
    /// List of images data stored externally to avoid bloating the database
    @Published var images_data: [Data] = []
    /// Optional list of image indexes that should be hidden from the user
    @Published var hidden_images: [Int]? = nil

    init(content: String? = nil, role: MessageRole? = nil, images: [Data] = [], hidden_images: [Int]? = nil) {
        self.content = content
        self.role = role
        self.images_data = images
        self.hidden_images = hidden_images
    }

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "Message")

    /// The full text of the message, including the audio text if it exists
    var text: String {
        let text = content ?? ""
        return text
    }

    /// Transient function to get non-hidden images
    var nonHiddenImages: [Data] {
        // Unwrap hidden_images and filter out hidden indexes
        let hiddenIndexes = hidden_images ?? []
        return images_data.enumerated().filter { index, _ in
            !hiddenIndexes.contains(index)
        }.map { _, data in
            data
        }
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

        let complete_text: String = self.text

        if allow_images, !images_data.isEmpty {
            // Images, multimodal
            let imageUrls = images_data.map { VisionContent.ChatCompletionContentPartImageParam.ImageURL(url: $0, detail: .auto) }
            let imageParams = imageUrls.map { VisionContent.ChatCompletionContentPartImageParam(imageUrl: $0) }
            let visionContent = imageParams.map { VisionContent(chatCompletionContentPartImageParam: $0) }

            let textParam = VisionContent.ChatCompletionContentPartTextParam(text: complete_text)
            let textVisionContent = [VisionContent(chatCompletionContentPartTextParam: textParam)]

            let content = textVisionContent + visionContent

            return ChatQuery.ChatCompletionMessageParam(role: role, content: content)
        } else {
            // Pure text
            return ChatQuery.ChatCompletionMessageParam(role: role, content: complete_text)
        }
    }

    static func fromAPI(_ message: APIMessage, files: [APIFile]) -> Message {
        let role = MessageRole.fromString(message.role)

        var imagesData: [Data] = []

        // Handling files as URLs or base64 data URLs
        for file in files {
            if let fileURL = file.url {
                if let url = URL(string: fileURL), url.scheme == "http" || url.scheme == "https" {
                    // Handle real URLs and download the data
                    if let imageData = try? Data(contentsOf: url) {
                        imagesData.append(imageData)
                    }
                } else if let base64Data = Data(base64Encoded: fileURL) {
                    // Handle base64-encoded data URLs
                    imagesData.append(base64Data)
                }
            }
        }

        return Message(content: message.text, role: role, images: imagesData)
    }
}

extension Message: CustomStringConvertible {
    var description: String {
        "\(role?.rawValue ?? ""): \(text)"
    }
}
