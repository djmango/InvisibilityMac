//
//  WhisperManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/18/24.
//

import Combine
import Foundation
import OllamaKit
import os
import SwiftData
import SwiftUI
import SwiftWhisper

struct ModelInfo {
    let url: URL
    let hash: String
    let localURL: URL
}

enum ModelRepository {
    static let WHISPER_SMALL = ModelInfo(
        url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin?download=true")!,
        hash: "ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb",
        localURL: DownloadManager.gravityHomeDir
            .appendingPathComponent("models")
            .appendingPathComponent("whisper")
            .appendingPathComponent("small.bin")
    )
}

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
            await self.messageViewModel.autorename()

            do {
                try await OllamaKit.shared.waitForAPI()

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

                var data = OKChatRequestData(
                    model: "mistral:latest",
                    messages: messages.compactMap { $0.toChatMessage() }
                )
                data.stream = false

                let result: OKChatResponse = try await OllamaKit.shared.achat(data: data)
                if let content = result.message?.content {
                    // Split by newline or period
                    let split = content.split(whereSeparator: { $0.isNewline || $0.isPunctuation })
                    let title = split.first ?? ""
                    audio.name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                audio.name = audio.segments.first?.text ?? "Audio"
                logger.error("Error waiting for API: \(error)")
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
    private let downloadManager: DownloadManager = DownloadManager()

    /// The Whisper model gets loaded asynchronously, so we need to wait for it to be ready
    private var downloadRetries = 0
    public var whisper: Whisper? {
        get async {
            while whisperModel == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                if downloadManager.state == .failed, downloadRetries < 100 {
                    downloadRetries += 1
                    let ourself = self
                    logger.debug("Waiting for Whisper to be ready (\(ourself.downloadRetries))")
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
            expectedHash: ModelRepository.WHISPER_SMALL.hash
        ) {
            logger.debug("Verified Whisper at \(ModelRepository.WHISPER_SMALL.localURL)")

            logger.debug("Loading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
            whisperModel = Whisper(fromFileURL: ModelRepository.WHISPER_SMALL.localURL)
        } else {
            logger.debug("Downloading Whisper from \(ModelRepository.WHISPER_SMALL.url)")
            do {
                try await downloadManager.download(
                    from: ModelRepository.WHISPER_SMALL.url,
                    to: ModelRepository.WHISPER_SMALL.localURL,
                    expectedHash: ModelRepository.WHISPER_SMALL.hash
                )

                logger.debug("Loading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
                whisperModel = Whisper(fromFileURL: ModelRepository.WHISPER_SMALL.localURL)
            } catch {
                logger.error("Could not download Whisper: \(error)")
            }
        }
    }

    func wipeWhisper() {
        try? FileManager.default.removeItem(at: ModelRepository.WHISPER_SMALL.localURL)
    }
}
