import Cocoa
import Combine
import CoreGraphics
import Foundation
import os
import SwiftData
import SwiftUI
import TelemetryClient
import UniformTypeIdentifiers
import ViewState
import Vision

@Observable
final class MessageViewModel: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "MessageViewModel")

    private let modelContext = SharedModelContainer.shared.mainContext
    private var chat: Chat
    private var chatTask: Task<Void, Error>?
    private var lastOpenedImage: Data?

    var messages: [Message] = []
    var sendViewState: ViewState? = nil

    init(chat: Chat) {
        self.chat = chat
    }

    deinit {
        logger.debug("MessageViewModel deinit")
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

        chatTask = Task {
            await LLMManager.shared.chat(messages: messages.dropLast(), processOutput: processOutput)

            assistantMessage.error = false
            assistantMessage.completed = true

            sendViewState = nil

            // If there are two messages, or the chat name is New Chat, we'll autorename
            if messages.count == 2 || chat.name == "New Chat" {
                await self.autorename()
            }
        }
    }

    @MainActor
    func regenerate(_: Message) async {
        TelemetryManager.send("MessageViewModel.regenerate")
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
                print("Error saving context after deletion: \(error)")
            }
        }
        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            await send(userMessage)
        }
    }

    func stopGenerate() {
        TelemetryManager.send("MessageViewModel.stopGenerate")
        logger.debug("Canceling generation")
        sendViewState = nil
        chatTask?.cancel()
        Task {
            do {
                try await WhisperManager.shared.whisper?.cancel()
            } catch {
                logger.error("Error canceling whisper: \(error)")
            }
        }

        Task {
            await LLMManager.shared.llm?.stop()
        }
    }

    private func processOutput(stream: AsyncStream<String>) async -> String {
        var result = ""
        for await line in stream {
            result += line

            DispatchQueue.main.async {
                if !self.messages.isEmpty, let lastMessage = self.messages.last {
                    if lastMessage.content == nil { lastMessage.content = "" }
                    lastMessage.content?.append(line)
                }

                self.sendViewState = .loading
            }
        }

        return result
    }
}

// @MARK AutoRename
extension MessageViewModel {
    @MainActor
    func autorename() async {
        TelemetryManager.send("MessageViewModel.autorename")

        // Copy the messages array and append the instruction message to it
        var message_history = messages.map { $0 }

        let instructionMessage = Message(content: AppPrompts.createShortTitle, role: .user)
        message_history.append(instructionMessage)

        let result: Message = await LLMManager.shared.achat(messages: message_history)
        if let content = result.content {
            logger.debug("Autorename result: \(content)")
            // Split by newline or period
            let split = content.split(whereSeparator: { $0.isNewline })
            let title = split.first ?? ""
            chat.name = title.trimmingCharacters(in: .whitespacesAndNewlines)
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
            UTType.image,
            UTType.audio,
            UTType.movie,
        ]

        // Technically doesn't work for the following types:
        // SVGs: Our image standardization function doesn't support SVGs
        // PDFs: Just need to add support for them
        // Video without audio: We don't support video without audio
        // TODO: fix the above issues

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                self.handleFile(url: url)
            }
        }
    }

    /// Public function that handles the file after it has been selected
    func handleFile(url: URL) {
        // First determine if we are dealing with an image or audio file
        logger.debug("Selected file \(url)")
        if let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            // Check if it's an image type
            if fileType.conforms(to: .image) {
                logger.debug("Selected file \(url) is an image.")
                handleImage(url: url)
            }
            // Check if it's an audio or video type
            else if fileType.conforms(to: .audio) || fileType.conforms(to: .movie) {
                if !isValidAudioFile(url: url) {
                    logger.error("Selected file \(url) is not a valid audio file.")
                    AlertManager.shared.doShowAlert(
                        title: AppMessages.invalidAudioFileTitle,
                        message: AppMessages.invalidAudioFileMessage
                    )
                    return
                }
                logger.debug("Selected file \(url) is an audio or video.")
                Task {
                    await self.handleAudio(url: url)
                }
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
            return
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return
        }

        // Standardize and convert the image to a base64 string and store it in the view model
        if let standardizedImage = standardizeImage(cgImage) {
            lastOpenedImage = standardizedImage
        }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            logger.error("Unable to perform the requests: \(error).")
        }
    }

    /// Async callback handler, takes the OCR results and spawns messages from them
    private func recognizeTextHandler(request: VNRequest, error _: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        guard let image = lastOpenedImage else { return }

        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            observation.topCandidates(1).first?.string
        }

        // Append the recognized strings to chat. Should design this better, just appending is dumb.
        let joined = recognizedStrings.joined(separator: " ")
        Task {
            await handleImageCompletion(image: image, joined: joined)
        }
    }

    @MainActor
    private func handleImageCompletion(image: Data, joined: String) {
        sendViewState = .loading

        // Create a new message with the recognized text
        let userMessage = Message(
            content: "Take a a look at this image for me", role: .user, chat: chat,
            images: [image]
        )

        // If joined is empty, we couldn't read anything from the image
        let assistantContent: String? = if !joined.isEmpty {
            "It says: \(joined)\n"
        } else {
            "I couldn't read anything from this image.\n"
        }
        let assistantMessage = Message(
            content: assistantContent, role: .assistant, chat: chat
        )

        // Add the messages to the view model
        messages.append(userMessage)
        messages.append(assistantMessage)
        modelContext.insert(userMessage)
        modelContext.insert(assistantMessage)
        lastOpenedImage = nil

        Task {
            await self.autorename()
        }

        sendViewState = nil
    }

    @MainActor
    private func handleAudio(url: URL) async {
        do {
            sendViewState = .loading

            // Add the message to the view model
            let message = Message(
                role: .user,
                chat: chat
            )

            messages.append(message)
            modelContext.insert(message)

            // Convert the audio file to a wav file and an array of PCM audio frames
            let (data, audioFrames) = try await convertAudioFileToWavAndPCMArray(fileURL: url)
            let audio = Audio(audioFile: data)
            modelContext.insert(audio)
            message.audio = audio
            AudioPlayerViewModel.shared.audio = audio

            let delegate = WhisperHandler(audio: audio, messageViewModel: self)
            await WhisperManager.shared.whisper?.delegate = delegate
            Task {
                _ = try await WhisperManager.shared.whisper?.transcribe(audioFrames: audioFrames)
            }

        } catch {
            logger.error("Error transcribing audio: \(error)")
            sendViewState = .error(message: "Error transcribing audio: \(error)")
        }
    }
}
