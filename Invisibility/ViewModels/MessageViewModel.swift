import Cocoa
import Combine
import CoreGraphics
import Foundation
import OSLog
import SwiftData
import SwiftUI
import TelemetryClient
import UniformTypeIdentifiers
import ViewState
import Vision

@Observable
final class MessageViewModel: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageViewModel")

    static let shared = MessageViewModel()

    private let modelContext = SharedModelContainer.shared.mainContext
    private var chatTask: Task<Void, Error>?
    private var lastOpenedImage: Data?

    var messages: [Message] = []
    var sendViewState: ViewState? = nil

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
        TelemetryManager.send("MessageViewModel.send")
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
                logger.error("Error saving context after deletion: \(error)")
            }
        }

        // Removes the user message and presents a fresh send scenario
        if let userMessage = messages.popLast() {
            await send(userMessage)
        }
    }

    func clearChat() {
        // TelemetryManager.send("MessageViewModel.clearChat")
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
            content: "Take a a look at this image for me",
            role: .user,
            images: [image]
        )

        // If joined is empty, we couldn't read anything from the image
        let assistantContent: String? = if !joined.isEmpty {
            "It says: \(joined)\n"
        } else {
            "I couldn't read anything from this image.\n"
        }
        let assistantMessage = Message(
            content: assistantContent,
            role: .assistant
        )

        // Add the messages to the view model
        messages.append(userMessage)
        messages.append(assistantMessage)
        modelContext.insert(userMessage)
        modelContext.insert(assistantMessage)
        lastOpenedImage = nil
        sendViewState = nil
    }

    @MainActor
    private func handleAudio(url: URL) async {
        do {
            sendViewState = .loading

            // Add the message to the view model
            let message = Message(role: .user)
            message.status = .audio_generation

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

                // If the audio is longer than x tokens, chunk it and summarize each chunk for easier processing
//                await message.generateSummarizedChunks()
                await message.generateEmail()
                DispatchQueue.main.async {
                    message.status = .complete
                    self.sendViewState = nil
                }
            }

        } catch {
            logger.error("Error transcribing audio: \(error)")
            sendViewState = .error(message: "Error transcribing audio: \(error)")
        }
    }
}
