//
//  WhisperViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/18/24.
//

import AudioKit
import Combine
import Foundation
import os
import SwiftData
import SwiftUI
import SwiftWhisper

class AudioStatus: ObservableObject {
    @Published var completed: Bool = false
    @Published var progress: Double = 0.0
    @Published var segments: [Segment] = []
    @Published var text: String = ""
    @Published var message: Message? = nil
}

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

func convertAudioFileToPCMArray(fileURL: URL) async throws -> [Float] {
    var options = FormatConverter.Options()
    options.format = .wav
    options.sampleRate = 16000
    options.bitDepth = 16
    options.channels = 1
    options.isInterleaved = false

    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)

    converter.start()

    let data = try Data(contentsOf: tempURL)

    let floats = stride(from: 44, to: data.count, by: 2).map {
        data[$0 ..< $0 + 2].withUnsafeBytes {
            let short = Int16(littleEndian: $0.load(as: Int16.self))
            return max(-1.0, min(Float(short) / 32767.0, 1.0))
        }
    }

    try? FileManager.default.removeItem(at: tempURL)

    return floats
}

class WhisperHandler: WhisperDelegate {
    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")
    @ObservedObject var audioStatus: AudioStatus
    @ObservedObject var messageViewModel: MessageViewModel

    init(audioStatus: AudioStatus, messageViewModel: MessageViewModel) {
        self.audioStatus = audioStatus
        self.messageViewModel = messageViewModel
    }

    func whisper(_: Whisper, didCompleteWithSegments segments: [Segment]) {
        logger.debug("Whisper didCompleteWithSegments: \(segments)")
        audioStatus.segments = segments
        audioStatus.completed = true
        audioStatus.progress = 1.0
        audioStatus.message?.done = true
        DispatchQueue.main.async { [weak self] in
            self?.messageViewModel.sendViewState = nil
        }
    }

    func whisper(_: Whisper, didErrorWith error: Error) {
        logger.error("Whisper didErrorWith: \(error)")
    }

    func whisper(_: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        logger.debug("Whisper didProcessNewSegments: \(segments) at index \(index)")
        audioStatus.segments.append(contentsOf: segments)
        for segment in segments {
            audioStatus.text += segment.text
            if audioStatus.message != nil {
                if audioStatus.message?.content == nil { audioStatus.message?.content = "" }

                DispatchQueue.main.async { [weak self] in
                    self?.audioStatus.message?.content? += segment.text
                }
            }
        }
    }

    func whisper(_: Whisper, didUpdateProgress progress: Double) {
        logger.debug("Whisper didUpdateProgress: \(progress)")
        audioStatus.progress = progress
    }
}

final class WhisperViewModel {
    static let shared = WhisperViewModel()

    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")

    private var whisperModel: Whisper?
    private let downloadManager: DownloadManager = DownloadManager()

    /// The Whisper model gets loaded asynchronously, so we need to wait for it to be ready
    public var whisper: Whisper? {
        get async {
            while whisperModel == nil {
                try? await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 second
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
        } else {
            logger.debug("Downloading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
            do {
                try await downloadManager.download(
                    from: ModelRepository.WHISPER_SMALL.url,
                    to: ModelRepository.WHISPER_SMALL.localURL,
                    expectedHash: ModelRepository.WHISPER_SMALL.hash
                )
            } catch {
                logger.error("Could not download Whisper: \(error)")
            }
        }

        logger.debug("Loading Whisper from \(ModelRepository.WHISPER_SMALL.localURL)")
        whisperModel = Whisper(fromFileURL: ModelRepository.WHISPER_SMALL.localURL)
    }
}
