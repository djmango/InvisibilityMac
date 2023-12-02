import Foundation
import SwiftData

@Model
final class OllamaModel: Identifiable {
    @Attribute(.unique) var name: String
    var isAvailable: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \Chat.model)
    var chats: [Chat] = []
    
    init(name: String) {
        self.name = name
    }
    
    @Transient var isNotAvailable: Bool {
        isAvailable == false
    }
}
