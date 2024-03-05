//
//  AudioFileWriter.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import AVFoundation
import Foundation
import OSLog

class AudioFileWriter {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "AudioFileWriter")

    static let invisibilityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".invisibility")
    static let audioDir = invisibilityHomeDir.appendingPathComponent("audio")

    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?

    init(outputURL: URL, audioSettings: [String: Any]) {
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .aiff)
            logger.debug("Audio file writer initialized at \(outputURL)")
            assetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true
            assetWriter?.add(assetWriterInput!)
        } catch {
            logger.error("Error initializing AVAssetWriter: \(error)")
        }
    }

    func startWriting() {
        assetWriter?.startWriting()
        assetWriter?.startSession(atSourceTime: CMTime.zero)
    }

    func handleAudio(for buffer: CMSampleBuffer) {
        try? buffer.withAudioBufferList { audioBufferList, _ in
            guard let description = buffer.formatDescription?.audioStreamBasicDescription,
                  let format = AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate, channels: description.mChannelsPerFrame),
                  let _ = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
            else { return }

            if assetWriterInput?.isReadyForMoreMediaData ?? false {
                assetWriterInput?.append(buffer)
            }
        }
    }

    func finishWriting() async {
        assetWriterInput?.markAsFinished()
        await withCheckedContinuation { continuation in
            assetWriter?.finishWriting {
                continuation.resume(returning: ())
            }
        }
    }
}
