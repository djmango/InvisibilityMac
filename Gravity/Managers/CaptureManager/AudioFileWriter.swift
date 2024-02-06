//
//  AudioFileWriter.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import AVFoundation
import Foundation
import OSLog

class AudioFileWriter {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AudioFileWriter")

    static let gravityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gravity")
    static let audioDir = gravityHomeDir.appendingPathComponent("audio")

    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?

    init(outputURL: URL, audioSettings: [String: Any]) {
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
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
                  // let samples = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
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
