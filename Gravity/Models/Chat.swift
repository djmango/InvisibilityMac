import Foundation
import SwiftData

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

        systemInstruction = UserDefaults.standard.string(forKey: "systemInstruction") ?? ""
        temperature = UserDefaults.standard.double(forKey: "temperature")
        maxContextLength = UserDefaults.standard.double(forKey: "maxContextLength")

        // let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? ""
        // print("Creating chat with model \(selectedModel)")
        // model = OllamaModel(name: selectedModel)
        // print("Created chat with model \(selectedModel)")
        systemInstruction = systemInstruction
        temperature = temperature
        maxContextLength = maxContextLength
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
