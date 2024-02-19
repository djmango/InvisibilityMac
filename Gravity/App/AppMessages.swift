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

    static let ollamaServerUnreachable = "The model could not be reached, if this continues try restarting the app."
    static let ollamaModelUnavailable = "This model is currently unavailable or has been removed."
    static let generalErrorMessage = "An error occurred. Please try again later."

    static let modelNotDownloadedTitle = "Model verification in progress"
    static let modelNotDownloadedMessage =
        "Please wait for the model to finish downloading and verifying.\nIf this is taking too long, wipe the models in settings and try again."
    static let couldNotCreateChatTitle = "Could not create chat"
    static let couldNotCreateChatMessage = "Please try again later."

    static let invalidAudioFileTitle = "No audio found"
    static let invalidAudioFileMessage = "File does not appear to have any audio."

    static let audioTranscriptionErrorTitle = "Audio transcription error"
    static let audioTranscriptionErrorMessage = "An error occurred while transcribing the audio."
}
