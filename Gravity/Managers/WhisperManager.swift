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

    private let audio: Audio

    @ObservedObject var messageViewModel: MessageViewModel

    init(audio: Audio, messageViewModel: MessageViewModel) {
        self.audio = audio
        self.messageViewModel = messageViewModel
    }

    @MainActor
    func whisper(_: Whisper, didCompleteWithSegments segments: [Segment]) {
        logger.debug("Whisper didCompleteWithSegments: \(segments)")
        audio.status = .complete
        audio.message?.progress = 1.0

        audio.name = audio.segments.first?.text ?? "Audio"
    }

    func whisper(_: Whisper, didErrorWith error: Error) {
        logger.error("Whisper didErrorWith: \(error)")
        audio.status = .error
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
        audio.message?.progress = progress
    }
}

final class WhisperManager {
    static let shared = WhisperManager()

    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")

    private var whisperModel: Whisper?
    public let modelFileManager: ModelFileManager = ModelFileManager(modelInfo: ModelRepository.Whisper_Small_English)

    /// The Whisper model gets loaded asynchronously, so we need to wait for it to be ready
    private var downloadRetries = 0
    public var whisper: Whisper? {
        get async {
            while whisperModel == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                if modelFileManager.state == .failed, downloadRetries < 100 {
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
        if modelFileManager.verifyFile(
            at: modelFileManager.modelInfo.localURL,
            expectedHash: modelFileManager.modelInfo.sha256
        ) {
            logger.debug("Verified and Loading \(self.modelFileManager.modelInfo.name) at \(self.modelFileManager.modelInfo.localURL)")
            load()
        } else {
            logger.debug("Downloading \(self.modelFileManager.modelInfo.name) from \(self.modelFileManager.modelInfo.url)")
            do {
                try await modelFileManager.download()

                logger.debug("Loading \(self.modelFileManager.modelInfo.name) from \(self.modelFileManager.modelInfo.localURL)")
                load()
            } catch {
                logger.error("Could not download \(self.modelFileManager.modelInfo.name): \(error)")
            }
        }
    }

    func load() {
        whisperModel = Whisper(fromFileURL: modelFileManager.modelInfo.localURL)
    }

    func wipe() {
        try? FileManager.default.removeItem(at: ModelRepository.Whisper_Small.localURL)
    }
}
