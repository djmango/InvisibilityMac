//
//  AudioFileWriter.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import Foundation

import AVFoundation

class AudioFileWriter {
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?

    init(outputURL: URL, audioSettings: [String: Any]) {
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
            assetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true
            assetWriter?.add(assetWriterInput!)
        } catch {
            print("Error initializing AVAssetWriter: \(error)")
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

    func finishWriting(completion: @escaping () -> Void = {}) {
        assetWriterInput?.markAsFinished()
        assetWriter?.finishWriting(completionHandler: completion)
    }
}
