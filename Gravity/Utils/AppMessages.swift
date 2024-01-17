import Foundation

enum AppMessages {
    static let chatDeletionTitle = "Are you sure you want to delete this chat?"
    static let chatDeletionMessage =
        "All messages in this conversation will be permanently removed."

    static let wipeAllDataTitle = "Are you sure you want to wipe all data?"
    static let wipeAllDataMessage =
        "All settings, chats, messages, and models will be permanently removed."

    static let wipeModelsTitle = "Are you sure you want to wipe all models?"
    static let wipeModelsMessage = "All models will be permanently removed."

    static let ollamaServerUnreachable = "The Ollama server cannot be reached at the moment."
    static let ollamaModelUnavailable = "This model is currently unavailable or has been removed."
    static let generalErrorMessage = "An error occurred. Please try again later."
}
