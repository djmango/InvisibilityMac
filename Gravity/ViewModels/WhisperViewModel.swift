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
}

func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
    var options = FormatConverter.Options()
    options.format = .wav
    options.sampleRate = 16000
    options.bitDepth = 16
    options.channels = 1
    options.isInterleaved = false

    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
    converter.start { error in
        if let error {
            completionHandler(.failure(error))
            return
        }

        let data = try! Data(contentsOf: tempURL) // Handle error here

        let floats = stride(from: 44, to: data.count, by: 2).map {
            data[$0 ..< $0 + 2].withUnsafeBytes {
                let short = Int16(littleEndian: $0.load(as: Int16.self))
                return max(-1.0, min(Float(short) / 32767.0, 1.0))
            }
        }

        try? FileManager.default.removeItem(at: tempURL)

        completionHandler(.success(floats))
    }
}

func convertAudioFileToPCMArrayAsync(fileURL: URL) async throws -> [Float] {
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

    init(audioStatus: AudioStatus) {
        self.audioStatus = audioStatus
    }

    func whisper(_: Whisper, didCompleteWithSegments segments: [Segment]) {
        logger.debug("Whisper didCompleteWithSegments: \(segments)")
        audioStatus.segments = segments
        audioStatus.completed = true
        audioStatus.progress = 1.0
    }

    func whisper(_: Whisper, didErrorWith error: Error) {
        logger.error("Whisper didErrorWith: \(error)")
    }

    func whisper(_: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        logger.debug("Whisper didProcessNewSegments: \(segments) at index \(index)")
        audioStatus.segments.append(contentsOf: segments)
        for segment in segments {
            audioStatus.text += segment.text
        }
    }

    func whisper(_: Whisper, didUpdateProgress progress: Double) {
        logger.debug("Whisper didUpdateProgress: \(progress)")
        audioStatus.progress = progress
    }
}

@Observable
final class WhisperViewModel: ObservableObject {
    static let shared = WhisperViewModel()

    private let logger = Logger(subsystem: "ai.grav.app", category: "WhisperViewModel")

    public let whisper: Whisper

    init() {
        // whisper = Whisper(fromFileURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin")!)
        // whisper = Whisper(fromFileURL: URL(string: "/Users/djmango/Downloads/ggml-small-q5_1.bin")!)
        whisper = Whisper(fromFileURL: URL(string: "/Users/djmango/Downloads/ggml-base.en-q5_1.bin")!)
    }
}
