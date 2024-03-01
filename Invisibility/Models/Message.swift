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
    /// The status of the message generation and processing
    var status: MessageStatus? = MessageStatus.pending
    /// The progress of the message processing this is generic and can be used for any processing, useful for UI
    var progress: Double = 0.0
    /// The child audio attached to the message
    @Relationship(deleteRule: .cascade, inverse: \Audio.message) var audio: Audio?

    /// Summarized chunks, just a list of strings for now, keep it simple
    var summarizedChunks: [String] = []

    init(content: String? = nil, role: MessageRole? = nil, images: [Data]? = nil) {
        self.content = content
        self.role = role
        self.images = images
    }

    @Transient
    private let logger = Logger(subsystem: "so.invisibility.app", category: "Message")

    /// The full text of the message, including the audio text if it exists
    @Transient var text: String {
        var text = content ?? ""
        if let audio {
            // If the message has been summarized, use the summarized chunks. Tbh not clean, but it works for now. I guess we treat text like a high-level macro
            if summarizedChunks.count > 0 {
                text += summarizedChunks.joined(separator: "\n\n")
            }
            // Otherwise, use the full audio text
            else {
                text += audio.text
            }
        }
        return text
    }
}

extension Message {
    public func generateSummarizedChunks() async {
        self.status = .chunk_summary_generation
        DispatchQueue.main.async { self.progress = 0.0 }

        self.summarizedChunks = []
        if self.summarizedChunks.count == 0, LLMManager.shared.numTokens(self.text) > LLMManager.maxTokenCountForMessage {
            let chunks = LLMManager.shared.chunkInputByTokenCount(input: self.text, maxTokenCount: 1024)
            DispatchQueue.main.async { self.progress = 0.2 }

            for (i, chunk) in chunks.enumerated().enumerated() {
                DispatchQueue.main.async { self.progress = 0.2 + (0.8 * (Double(i) / Double(chunks.count))) }
                let content = "\(chunk)\n\n\(AppPrompts.summarizeChunk)"
                // let chunkChat = ChatQuery.ChatCompletionMessageParam(role: .user, content: content)
                let chunkMessage = Message(content: content, role: .user)
                let output = await LLMManager.shared.achat(messages: [chunkMessage])
                if let output_content = output.content {
                    self.summarizedChunks.append(output_content)
                } else {
                    logger.error("No content in output for chunk \(i): \(chunkMessage)")
                }
            }

            logger.debug("Completed summarization. Chunks: \(self.summarizedChunks)")
        }
    }

    public func generateEmail(open: Bool = false) async {
        guard let audio = self.audio else {
            logger.error("Audio not available")
            return
        }

        if audio.email == nil {
            DispatchQueue.main.async { self.status = .email_generation }
            DispatchQueue.main.async { self.progress = 0.0 }

            await generateFollowUp(self.text, message: self)
        }
        DispatchQueue.main.async { self.status = .complete }

        if let email = audio.email, open {
            // Extract subject via regex
            let subject = email.extractAfter(pattern: "Subject: ") ?? "Follow Up"

            // Replace subject in body
            let body = email.replacingOccurrences(of: "Subject: \(subject)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            let mailto = encodeForMailto(subject: subject, body: body)
            if let url = URL(string: mailto), open {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension Message {
    func toChat() -> ChatQuery.ChatCompletionMessageParam? {
        var role: ChatQuery.ChatCompletionMessageParam.Role = .user
        if self.role == .assistant {
            role = .assistant
        } else if self.role == .system {
            role = .system
        }

        if let images = self.images {
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
