import Foundation
import SwiftData

@Model
final class Chat: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    
    var name: String
    var createdAt: Date = Date.now
    var modifiedAt: Date = Date.now

    @Relationship
    var model: OllamaModel?

    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message] = []
    
    init(name: String) {
        self.name = name
    }
    
    static func example() -> Chat {
        let example = Chat(name: "Example")
        example.messages = [Message(content: "Yo", role: Role.user, chat: example)]
        return example
    }
}
