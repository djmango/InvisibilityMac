//
//  AudioUtils.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/23/24.
//

import AudioKit
import AVFoundation
import Foundation
import os

private let logger = Logger(subsystem: "ai.grav.app", category: "AudioUtils")

func isValidAudioFile(url: URL) -> Bool {
    do {
        let _ = try AVAudioFile(forReading: url)
        return true
    } catch {
        logger.error("Error: \(error.localizedDescription)")
        return false
    }
}

func convertAudioFileToWavAndPCMArray(fileURL: URL) async throws -> (Data, [Float]) {
    var options = FormatConverter.Options()
    options.format = .wav
    options.sampleRate = 16000
    options.bitDepth = 16
    options.channels = 1
    options.isInterleaved = false
    // options.bitRate = 256 * 1000

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

    return (data, floats)
}
