import Foundation
import SwiftData
import SwiftUI

@Model
final class Chat: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()

    var name: String
    var createdAt: Date = Date.now
    var modifiedAt: Date = Date.now

    // Settings. Will be set to settings from application on chat instantiation.
    var systemInstruction: String = ""
    var temperature: Double = 0.7
    var maxContextLength: Double = 6000

    @Relationship
    var model: OllamaModel?

    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message] = []

    init(name: String = "New Chat") {
        self.name = name

        @AppStorage("selectedModel") var selectedModel = "mistral:latest"
        @AppStorage("systemInstruction") var systemInstruction = ""
        @AppStorage("temperature") var temperature: Double = 0.7
        @AppStorage("maxContextLength") var maxContextLength: Double = 6000

        model = OllamaModel(name: selectedModel)
        self.systemInstruction = systemInstruction
        self.temperature = temperature
        self.maxContextLength = maxContextLength
    }
}

// MARK: - Hashable

extension Chat: Hashable {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
