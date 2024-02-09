//
//  WhisperManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/18/24.
//

import Combine
import Foundation
import OSLog
import SwiftData
import SwiftUI
import SwiftWhisper

class WhisperHandler: WhisperDelegate {
    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")

    private let modelContext = SharedModelContainer.shared.mainContext

    private let audio: Audio

    @ObservedObject var messageViewModel: MessageViewModel

    init(audio: Audio, messageViewModel: MessageViewModel) {
        self.audio = audio
        self.messageViewModel = messageViewModel
    }

    @MainActor
    func whisper(_: Whisper, didCompleteWithSegments segments: [Segment]) {
        logger.debug("Whisper didCompleteWithSegments: \(segments)")
        messageViewModel.sendViewState = nil
        audio.completed = true
        audio.progress = 1.0

        Task {
            var messages: [Message] = []

            let transcriptMessage = Message(
                content: audio.text,
                role: .user
            )

            let instructionMessage = Message(
                content: AppPrompts.createShortTitle,
                role: .user
            )

            messages.append(transcriptMessage)
            messages.append(instructionMessage)

            let result: Message = await LLMManager.shared.achat(messages: messages)

            if let content = result.content {
                logger.debug("Audio name result: \(content)")
                // Split by newline or period
                let split = content.split(whereSeparator: { $0.isNewline })
                let title = split.first ?? ""
                audio.name = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    func whisper(_: Whisper, didErrorWith error: Error) {
        logger.error("Whisper didErrorWith: \(error)")
        audio.error = true
        DispatchQueue.main.async {
            self.messageViewModel.sendViewState = .error(message: error.localizedDescription)
        }
    }

    @MainActor
    func whisper(_: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        logger.debug("Whisper didProcessNewSegments: \(segments) at index \(index)")
        let audioSegments = AudioSegment.fromSegments(segments: segments)
        audio.segments.append(contentsOf: audioSegments)
    }

    @MainActor
    func whisper(_: Whisper, didUpdateProgress progress: Double) {
        logger.debug("Whisper didUpdateProgress: \(progress)")
        audio.progress = progress
    }
}

final class WhisperManager {
    static let shared = WhisperManager()

    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")

    private var whisperModel: Whisper?
    public let downloadManager: ModelFileManager = ModelFileManager(modelInfo: ModelRepository.WHISPER_SMALL)

    /// The Whisper model gets loaded asynchronously, so we need to wait for it to be ready
    private var downloadRetries = 0
    public var whisper: Whisper? {
        get async {
            while whisperModel == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                if downloadManager.state == .failed, downloadRetries < 100 {
                    downloadRetries += 1
                    logger.debug("Waiting for Whisper to be ready (\(self.downloadRetries))")
                    await setup()
                }
            }
            return whisperModel
        }
    }

    private init() {}

    func setup() async {
        if downloadManager.verifyFile(
            at: ModelRepository.WHISPER_SMALL.localURL,
            expectedHash: ModelRepository.WHISPER_SMALL.sha256
        ) {
            logger.debug("Verified Whisper at \(ModelRepository.WHISPER_SMALL.localURL)")

            logger.debug("Loading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
            whisperModel = Whisper(fromFileURL: ModelRepository.WHISPER_SMALL.localURL)
        } else {
            logger.debug("Downloading Whisper from \(ModelRepository.WHISPER_SMALL.url)")
            do {
                try await downloadManager.download()

                logger.debug("Loading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
                whisperModel = Whisper(fromFileURL: ModelRepository.WHISPER_SMALL.localURL)
            } catch {
                logger.error("Could not download Whisper: \(error)")
            }
        }
    }

    func wipe() {
        try? FileManager.default.removeItem(at: ModelRepository.WHISPER_SMALL.localURL)
    }
}
