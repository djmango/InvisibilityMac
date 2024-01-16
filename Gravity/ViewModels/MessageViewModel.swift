import Cocoa
import Combine
import CoreGraphics
import Foundation
import OllamaKit
import os
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

    private let logger = Logger(subsystem: "ai.grav.app", category: "MessageViewModel")

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
        if OllamaViewModel.shared.mistralDownloadStatus != .complete {
            sendViewState = .error(message: "Please wait for the model to finish downloading.")
            return
        }

        TelemetryManager.send("MessageViewModel.send")
        sendViewState = .loading

        messages.append(message)
        modelContext.insert(message)

        let assistantMessage = Message(content: nil, role: .assistant, chat: chat)
        messages.append(assistantMessage)
        modelContext.insert(assistantMessage)

        try? modelContext.saveChanges()

        if await OllamaKit.shared.reachable() {
            // Use compactMap to drop nil values and dropLast
            // to drop the assistant message from the context we are sending to the LLM
            let data = OKChatRequestData(
                model: chat.model?.name ?? "mistral:latest",
                messages: messages.dropLast().compactMap { $0.toChatMessage() }
            )

            generation = OllamaKit.shared.chat(data: data)
                .handleEvents(
                    receiveSubscription: { _ in self.logger.debug("Received Subscription") },
                    receiveOutput: { _ in self.logger.debug("Received Output") },
                    receiveCompletion: { _ in self.logger.debug("Received Completion") },
                    receiveCancel: { self.logger.debug("Received Cancel") }
                )
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .finished:
                            self?.logger.debug("Success completion")
                            self?.handleComplete()

                            // When complete, we can autorename the chat if it is a new chat.
                            if self?.messages.count == 2 {
                                Task {
                                    await self?.autorename()
                                }
                            }

                        case let .failure(error):
                            self?.logger.error("Failure completion \(error)")
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
        if OllamaViewModel.shared.mistralDownloadProgress < 1.0 {
            sendViewState = .error(message: "Please wait for the model to finish downloading.")
            return
        }
        TelemetryManager.send("MessageViewModel.regenerate")
        sendViewState = .loading
        do {
            try await OllamaKit.shared.waitForAPI(restart: true)
            // Handle the case when the API restarts successfully
            logger.debug("API restarted successfully.")
            // Update the UI or proceed with the next steps
        } catch {
            // Handle the failure case
            logger.error("Failed to restart the API.")
            sendViewState = .error(
                message: "Failed to restart the API. Please try again later.")
            // Update the UI to show an error message
        }

        // For easy code reuse, essentially what we're doing here is resetting the state to before the message we want to regenerate was generated
        // So for that, we'll recreate the original send scenario, when the new user message was sent
        // We'll delete it the last two messages, the user message and the assistant message we want to regenerate
        // This assumes chat structure is always user -> assistant -> user

        if messages.count < 2 { return }
        // Remove the assistant message we are regenerating from class and ModelContext
        if let assistantMessage = messages.popLast() {
            modelContext.delete(assistantMessage)
        }
        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            modelContext.delete(userMessage)
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
        // Task {
        //     await OllamaKit.shared.restartBinaryAndWaitForAPI()
        // }
    }

    private func handleComplete() {
        TelemetryManager.send("MessageViewModel.handleComplete")
        if messages.isEmpty { return }

        messages.last?.error = false
        messages.last?.done = true

        do {
            try modelContext.saveChanges()
        } catch {
            logger.error("Error saving changes: \(error)")
        }

        sendViewState = nil
    }
}

// @MARK AutoRename
extension MessageViewModel {
    @MainActor
    func autorename() async {
        TelemetryManager.send("MessageViewModel.autorename")

        if await OllamaKit.shared.reachable() {
            // Copy the messages array and append the instruction message to it
            var message_history = messages.map { $0 }

            let instructionMessage = Message(content: "Generate a 2-4 word desctriptor of the above chat. Do not write any additional text, return only the short descriptor. Please be concise. For example, \"AI for Industrial Robots\".", role: .user)
            message_history.append(instructionMessage)

            var data = OKChatRequestData(
                model: chat.model?.name ?? "mistral:latest",
                messages: message_history.compactMap { $0.toChatMessage() }
            )
            data.stream = false

            generation = OllamaKit.shared.chat(data: data)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .finished:
                            self?.logger.debug("Success completion")
                        case let .failure(error):
                            self?.logger.error("Failure completion \(error)")
                        }
                    },
                    receiveValue: { [weak self] response in
                        guard let message = response.message else { return }
                        self?.logger.debug("Received chat name: \(message.content)")
                        self?.chat.name = message.content
                    }
                )
        } else {
            handleError(AppMessages.ollamaServerUnreachable)
        }
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
                    self.logger.error("Unable to perform the requests: \(error).")
                }
            } else {
                self.logger.error("ERROR: Couldn't grab file url for some reason")
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

        // If joined is empty, we couldn't read anything from the image
        let assistantContent: String? = if !joined.isEmpty {
            "It says: \(joined)\n"
        } else {
            "I couldn't read anything from this image.\n"
        }
        let assistantMessage = Message(
            content: assistantContent, role: Role.assistant, chat: chat
        )

        // Add the messages to the view model and save them to the database
        messages.append(userMessage)
        messages.append(assistantMessage)
        modelContext.insert(userMessage)
        modelContext.insert(assistantMessage)
        do {
            try modelContext.saveChanges()
        } catch {
            logger.error("Error saving changes: \(error)")
        }
        lastOpenedImage = nil

        do {
            try modelContext.saveChanges()
        } catch {
            logger.error("Error saving changes: \(error)")
        }

        sendViewState = nil
    }
}
