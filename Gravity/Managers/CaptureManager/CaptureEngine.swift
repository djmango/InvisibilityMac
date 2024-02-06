//
//  CaptureEngine.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import AVFAudio
import AVFoundation
import Combine
import CoreGraphics
import Foundation
import OSLog
import ScreenCaptureKit

/// An object that wraps an instance of `SCStream`, and returns its results as an `AsyncThrowingStream`.
class CaptureEngine: NSObject, @unchecked Sendable {
    private let logger = Logger(subsystem: "ai.grav.app", category: "CaptureEngine")

    private(set) var stream: SCStream?
    private var streamOutput: CaptureEngineStreamOutput?
    private let audioSampleBufferQueue = DispatchQueue(label: "ai.grav.app.AudioSampleBufferQueue")

    // Performs average and peak power calculations on the audio samples.
    private let powerMeter = PowerMeter()
    var audioLevels: AudioLevels { powerMeter.levels }

    /// The audio recorder used to capture audio from the mic.
    private var audioRecorder: AVAudioRecorder?

    // Store the the startCapture continuation, so that you can cancel it when you call stopCapture().
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    /// An error type for the capture engine.
    enum CaptureError: Error {
        case invalidURL
        case createTrackFailed
        case exportFailed
    }

    /// The settings for audio recording.
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 48000,
        AVEncoderBitRateKey: 256_000,
    ]

    /// A date formatter for creating unique file names.
    private let dateFormatter = DateFormatter()

    /// The base folder for the file(s) to write audio to.
    private var fileFolder: URL?

    /// The URL for the system audio file.
    private var systemFileURL: URL? {
        guard let fileFolder else { return nil }
        return fileFolder.appendingPathComponent("system").appendingPathExtension("m4a")
    }

    /// The URL for the mic audio file.
    private var micFileURL: URL? {
        guard let fileFolder else { return nil }
        return fileFolder.appendingPathComponent("mic").appendingPathExtension("m4a")
    }

    /// The URL for the merged audio file.
    private var mergedFileURL: URL? {
        guard let fileFolder else { return nil }
        return fileFolder.appendingPathComponent("merged").appendingPathExtension("m4a")
    }

    override init() {
        super.init()
        dateFormatter.dateFormat = "MMM_dd_yyyy_HH_mm_ss"
    }

    /// - Tag: StartCapture
    func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            // The stream output object. Avoid reassigning it to a new object every time startCapture is called.
            let streamOutput = CaptureEngineStreamOutput(continuation: continuation)
            self.streamOutput = streamOutput
            streamOutput.pcmBufferHandler = { self.powerMeter.process(buffer: $0) }

            // Create directory for audio files
            fileFolder = AudioFileWriter.audioDir.appendingPathComponent(dateFormatter.string(from: Date()))
            guard let fileFolder else {
                continuation.finish(throwing: CaptureError.invalidURL)
                return
            }
            try? FileManager.default.createDirectory(at: fileFolder, withIntermediateDirectories: true, attributes: nil)

            guard let systemFileURL, let micFileURL else {
                continuation.finish(throwing: CaptureError.invalidURL)
                return
            }

            streamOutput.audioFileWriter = AudioFileWriter(outputURL: systemFileURL, audioSettings: audioSettings)
            streamOutput.audioFileWriter?.startWriting()

            do {
                audioRecorder = try AVAudioRecorder(url: micFileURL, settings: audioSettings)
                audioRecorder?.record()

                stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)

                // Add a stream output to capture screen content.
                try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: nil)
                try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
                stream?.startCapture()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            audioRecorder?.stop()
            audioRecorder = nil

            await streamOutput?.audioFileWriter?.finishWriting()

            // Merge audio files after writing is finished
            self.streamOutput?.audioFileWriter = nil

            do {
                guard let systemFileURL = self.systemFileURL, let micFileURL = self.micFileURL, let mergedFileURL = self.mergedFileURL else {
                    self.logger.error("Invalid audio file URLs")
                    AlertManager.shared.doShowAlert(title: "Error", message: "Invalid audio file URLs. If this error persists, please contact support.")
                    return
                }
                try await self.overlayAudioFiles(audioFileURLs: [systemFileURL, micFileURL], outputURL: mergedFileURL)

                // Now send it to the chat
                MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).handleFile(url: mergedFileURL)
            } catch {
                self.logger.error("Error merging audio files: \(error)")
                AlertManager.shared.doShowAlert(title: "Error", message: "Error merging audio files: \(error). If this error persists, please contact support.")
            }

            continuation?.finish()
        } catch {
            continuation?.finish(throwing: error)
        }
        powerMeter.processSilence()
    }

    /// - Tag: UpdateStreamConfiguration
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
        }
    }

    // func mergeAudioFiles(fileURLs: [URL], outputURL: URL) async throws {
    //     let composition = AVMutableComposition()
    //     guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
    //         throw CaptureError.createTrackFailed
    //     }

    //     for fileURL in fileURLs {
    //         let asset = AVURLAsset(url: fileURL)

    //         // Load tracks asynchronously
    //         try await asset.loadTracks(withMediaType: .audio)
    //         guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }

    //         // Load duration
    //         let duration = try await asset.load(.duration)

    //         do {
    //             try track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration),
    //                                       of: assetTrack,
    //                                       at: composition.duration)
    //         } catch {
    //             // Handle error
    //             print("Error inserting time range: \(error)")
    //         }
    //     }

    //     // Configure and start the export session
    //     guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
    //         throw CaptureError.exportFailed
    //     }
    //     exporter.outputURL = outputURL
    //     exporter.outputFileType = .m4a

    //     // Perform the export asynchronously
    //     await exporter.export()
    // }

    /// Merges two audio files into one by overlaying them.
    func overlayAudioFiles(audioFileURLs: [URL], outputURL: URL) async throws {
        let composition = AVMutableComposition()

        // Ensure there are two audio files to overlay
        guard audioFileURLs.count == 2 else { return }

        // Attempt to create two tracks in the composition for each audio file
        guard let trackA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
              let trackB = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            throw CaptureError.createTrackFailed
        }

        for (index, fileURL) in audioFileURLs.enumerated() {
            let asset = AVURLAsset(url: fileURL)

            // Choose the correct track for the current file
            let track = (index == 0) ? trackA : trackB

            // Load tracks asynchronously
            try await asset.loadTracks(withMediaType: .audio)
            guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }

            // Load duration
            let duration = try await asset.load(.duration)

            try track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration),
                                      of: assetTrack,
                                      at: .zero) // Start both tracks at the same time
        }

        // Export the mixed audio
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureError.exportFailed
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        // exporter.audioMix = audioMix // If you have an AVMutableAudioMix for volume adjustments

        // Perform the export
        await exporter.export()
    }
}

/// A class that handles output from an SCStream, and handles stream errors.
private class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    var audioFileWriter: AudioFileWriter?

    // Store the  startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    init(continuation: AsyncThrowingStream<String, Error>.Continuation?) {
        self.continuation = continuation
    }

    /// - Tag: DidOutputSampleBuffer
    func stream(_: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        // Return early if the sample buffer is invalid.
        guard sampleBuffer.isValid else { return }

        // Determine which type of data the sample buffer contains.
        switch outputType {
        case .screen:
            break
        case .audio:
            // Process audio as an AVAudioPCMBuffer for level calculation.
            handleAudio(for: sampleBuffer)
        @unknown default:
            fatalError("Encountered unknown stream output type: \(outputType)")
        }
    }

    private func handleAudio(for buffer: CMSampleBuffer) -> Void? {
        // Create an AVAudioPCMBuffer from an audio sample buffer.
        try? buffer.withAudioBufferList { audioBufferList, _ in
            guard let description = buffer.formatDescription?.audioStreamBasicDescription,
                  let format = AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate, channels: description.mChannelsPerFrame),
                  let samples = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
            else { return }
            pcmBufferHandler?(samples)
            self.audioFileWriter?.handleAudio(for: buffer)
        }
    }

    func stream(_: SCStream, didStopWithError error: Error) {
        continuation?.finish(throwing: error)
    }
}
