import Cocoa
import Combine
import CoreGraphics
import Foundation
import OllamaKit
import SwiftData
import SwiftUI
 import TelemetryClient
import UniformTypeIdentifiers
import ViewState
import Vision

@Observable
final class MessageViewModel: ObservableObject {
    private var generation: AnyCancellable?

    private var chat: Chat
    private var modelContext: ModelContext
    private var lastOpenedImage: Data?

    var messages: [Message] = []
    var sendViewState: ViewState? = nil

    init(chat: Chat, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.chat = chat
    }

    deinit {
        self.stopGenerate()
    }

    func fetch(for chat: Chat) throws {
        TelemetryManager.send("MessageViewModel.fetch")
        let chatID = chat.id
        let predicate = #Predicate<Message> { $0.chat?.id == chatID }
        let sortDescriptor = SortDescriptor(\Message.createdAt)
        let fetchDescriptor = FetchDescriptor<Message>(
            predicate: predicate, sortBy: [sortDescriptor]
        )

        messages = try modelContext.fetch(fetchDescriptor)
    }

    @MainActor
    func send(_ message: Message) async {
        TelemetryManager.send("MessageViewModel.send")
        sendViewState = .loading

        messages.append(message)
        modelContext.insert(message)

        let assistantMessage = Message(content: nil, role: .assistant, chat: chat)
        messages.append(assistantMessage)
        modelContext.insert(assistantMessage)

        try? modelContext.saveChanges()

        if await OllamaKit.shared.reachable() {
            // Use compactMap to drop nil values and dropLast to drop the assistant message from the context we are sending to the LLM
            let data = OKChatRequestData(
                model: message.model,
                messages: messages.dropLast().compactMap { $0.toChatMessage() }
            )

            generation = OllamaKit.shared.chat(data: data)
                .handleEvents(
                    receiveSubscription: { _ in print("Received Subscription") },
                    receiveOutput: { _ in print("Received Output") },
                    receiveCompletion: { _ in print("Received Completion") },
                    receiveCancel: { print("Received Cancel") }
                )
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .finished:
                            print("Success completion")
                            self?.handleComplete()
                        case let .failure(error):
                            print("Failure completion \(error)")
                            self?.handleError(error.localizedDescription)
                        }
                    },
                    receiveValue: { [weak self] response in
                        self?.handleReceive(response)
                    }
                )
        } else {
            handleError(AppMessages.ollamaServerUnreachable)
        }
    }

    @MainActor
    func regenerate(_: Message) async {
        TelemetryManager.send("MessageViewModel.regenerate")
        sendViewState = .loading
        let restarted = await OllamaKit.shared.restartBinaryAndWaitForAPI()
        if restarted {
            // Handle the case when the API restarts successfully
            print("API restarted successfully.")
            // Update the UI or proceed with the next steps
        } else {
            // Handle the failure case
            print("Failed to restart the API.")
            sendViewState = .error(
                message: "Failed to restart the API. Please try again later.")
            // Update the UI to show an error message
        }

        // For easy code reuse, essentially what we're doing here is resetting the state to before the message we want to regenerate was generated
        // So for that, we'll recreate the original send scenario, when the new user message was sent
        // We'll delete it the last two messages, the user message and the assistant message we want to regenerate
        // This assumes chat structure is always user -> assistant -> user

        if messages.count < 2 { return }
        messages.removeLast() // Removes the assistant message we are regenerating
        if let userMessage = messages.popLast() { // Removes the user message and presents a fresh send scenario
            await send(userMessage)
        }
    }

    func stopGenerate() {
        TelemetryManager.send("MessageViewModel.stopGenerate")
        sendViewState = nil
        generation?.cancel()
        try? modelContext.saveChanges()
    }

    private func handleReceive(_ response: OKChatResponse) {
        if messages.isEmpty { return }
        guard let message = response.message else { return }
        guard let lastMessage = messages.last else { return }

        if lastMessage.content == nil { lastMessage.content = "" }
        lastMessage.content?.append(message.content)

        sendViewState = .loading
    }

    private func handleError(_ errorMessage: String) {
        TelemetryManager.send("MessageViewModel.handleError")
        if messages.isEmpty { return }

        messages.last?.error = true
        messages.last?.done = false

        try? modelContext.saveChanges()
        sendViewState = .error(message: errorMessage)
    }

    private func handleComplete() {
        TelemetryManager.send("MessageViewModel.handleComplete")
        if messages.isEmpty { return }

        messages.last?.error = false
        messages.last?.done = true

        do {
            try modelContext.saveChanges()
        } catch {
            print("Error saving changes: \(error)")
        }

        sendViewState = nil
    }
}

// @MARK Image Handler
extension MessageViewModel {
    /// Public function that can be called to begin the file open process
    func openFile() {
        TelemetryManager.send("MessageViewModel.openFile")
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        // Define allowed content types using UTType
        openPanel.allowedContentTypes = [
            UTType.png,
            UTType.jpeg,
            UTType.gif,
            UTType.bmp,
            UTType.tiff,
            UTType.heif,
        ]

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    return
                }
                guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                    return
                }

                self.sendViewState = .loading

                // Standardize and convert the image to a base64 string and store it in the view model
                if let standardizedImage = standardizeImage(cgImage) {
                    self.lastOpenedImage = standardizedImage
                }

                // Create a new image-request handler.
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)

                // Create a new request to recognize text.
                let request = VNRecognizeTextRequest(completionHandler: self.recognizeTextHandler)
                do {
                    // Perform the text-recognition request.
                    try requestHandler.perform([request])
                } catch {
                    print("Unable to perform the requests: \(error).")
                }
            } else {
                print("ERROR: Couldn't grab file url for some reason")
            }
        }
    }

    /// Async callback handler, takes the OCR results and spawns messages from them
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        guard let image = lastOpenedImage else { return }

        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            observation.topCandidates(1).first?.string
        }

        // Append the recognized strings to chat. Should design this better, just appending is dumb.
        let joined = recognizedStrings.joined(separator: " ")

        // Create a new message with the recognized text
        let userMessage = Message(
            content: "Take a a look at this image for me", role: Role.user, chat: chat,
            images: [image]
        )
        let assistantMessage = Message(
            content: "It says: \(joined)", role: Role.assistant, chat: chat
        )

        // Add the messages to the view model and save them to the database
        messages.append(userMessage)
        messages.append(assistantMessage)
        modelContext.insert(userMessage)
        modelContext.insert(assistantMessage)
        do {
            try modelContext.saveChanges()
        } catch {
            print("Error saving changes: \(error)")
        }
        sendViewState = nil
        lastOpenedImage = nil
    }
}
