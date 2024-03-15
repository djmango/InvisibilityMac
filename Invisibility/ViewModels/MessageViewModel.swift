import Cocoa
import Combine
import CoreGraphics
import Foundation
import OSLog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import ViewState
import Vision

@Observable
final class MessageViewModel: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageViewModel")

    static let shared = MessageViewModel()

    private let modelContext = SharedModelContainer.shared.mainContext
    private let chatViewModel = ChatViewModel.shared

    private var chatTask: Task<Void, Error>?

    /// The list of messages in the chat
    public var messages: [Message] = []

    /// The current view state of the message being sent
    public var sendViewState: ViewState? = nil

    private init() {
        try? fetch()
    }

    func fetch() throws {
        let sortDescriptor = SortDescriptor(\Message.createdAt)
        let fetchDescriptor = FetchDescriptor<Message>(
            sortBy: [sortDescriptor]
        )

        messages = try modelContext.fetch(fetchDescriptor)
        logger.debug("Fetched \(self.messages.count) messages")
    }

    @MainActor
    func send(_ message: Message) async {
        sendViewState = .loading

        messages.append(message)
        modelContext.insert(message)

        let assistantMessage = Message(content: nil, role: .assistant)
        messages.append(assistantMessage)
        modelContext.insert(assistantMessage)

        chatTask = Task {
            await LLMManager.shared.chat(messages: messages.dropLast(), processOutput: processOutput)

            assistantMessage.status = .complete
            sendViewState = nil
        }
    }

    @MainActor
    func regenerate() async {
        sendViewState = .loading

        // For easy code reuse, essentially what we're doing here is resetting the state to before the message we want to regenerate was generated
        // So for that, we'll recreate the original send scenario, when the new user message was sent
        // We'll delete it the last two messages, the user message and the assistant message we want to regenerate
        // This assumes chat structure is always user -> assistant -> user

        if messages.count < 2 { return }
        // Remove the assistant message we are regenerating from class and ModelContext
        if let assistantMessage = messages.popLast() {
            modelContext.delete(assistantMessage)
            do {
                try modelContext.save()
            } catch {
                // Handle the error, such as logging or showing an alert to the user
                logger.error("Error saving context after deletion: \(error)")
            }
        }

        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            await send(userMessage)
        }
    }

    func clearChat() {
        logger.debug("Clearing chat")
        for message in messages {
            modelContext.delete(message)
        }
        messages.removeAll()
    }

    private func processOutput(output: String) {
        DispatchQueue.main.async {
            if !self.messages.isEmpty, let lastMessage = self.messages.last {
                if lastMessage.content == nil { lastMessage.content = "" }
                lastMessage.content?.append(output)
            }

            self.sendViewState = .loading
        }
    }
}

// @MARK File Handler
extension MessageViewModel {
    /// Public function that can be called to begin the file open process
    func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        // Define allowed content types using UTType
        openPanel.allowedContentTypes = [
            UTType.image,
        ]

        // Technically doesn't work for the following types:
        // SVGs: Our image standardization function doesn't support SVGs
        // PDFs: Just need to add support for them
        // TODO: fix the above issues

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                self.handleFile(url)
            }
        }
    }

    /// Public function that handles file via a URL regarding a message
    public func handleFile(_ url: URL) {
        // First determine if we are dealing with an image or audio file
        logger.debug("Selected file \(url)")
        if let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            // Check if it's an image type
            if fileType.conforms(to: .image) {
                logger.debug("Selected file \(url) is an image.")
                handleImage(url: url)
            } else {
                logger.error("Selected file \(url) is of an unknown type.")
                AlertManager.shared.doShowAlert(
                    title: "Unknown file type",
                    message: "The selected file \(url) is of an unknown type."
                )
            }
        }
    }

    private func handleImage(url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            logger.error("Failed to create image source from url.")
            return
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            logger.error("Failed to create image from image source.")
            return
        }

        // Standardize and convert the image to a base64 string and store it in the view model
        guard let standardizedImage = standardizeImage(cgImage) else {
            logger.error("Failed to standardize image.")
            return
        }

        DispatchQueue.main.async {
            self.chatViewModel.addImage(standardizedImage)
        }
    }
}
