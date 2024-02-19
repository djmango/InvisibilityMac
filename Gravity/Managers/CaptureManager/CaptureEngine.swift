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

    /// The audio recorder used to capture audio from the mic.
    private var audioRecorder: AVAudioRecorder?

    /// Store the the startCapture continuation, so that you can cancel it when you call stopCapture().
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    /// An error type for the capture engine.
    enum CaptureError: Error {
        case invalidURL
        case createTrackFailed
        case exportFailed
    }

    /// The settings for audio recording.
    // private let audioSettings: [String: Any] = [
    //     AVFormatIDKey: kAudioFormatMPEG4AAC,
    //     AVNumberOfChannelsKey: 2,
    //     AVSampleRateKey: 48000,
    //     AVEncoderBitRateKey: 256_000,
    // ]

    private let audioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, // AIFF uses linear PCM
        AVNumberOfChannelsKey: 2, // Stereo audio
        AVSampleRateKey: 44100, // Standard CD-quality sample rate
        AVLinearPCMBitDepthKey: 16, // Common bit depth for CD quality
        AVLinearPCMIsBigEndianKey: true, // AIFF is typically big-endian
        AVLinearPCMIsFloatKey: false, // AIFF uses integer PCM, not floating-point
        AVLinearPCMIsNonInterleaved: false, // Interleaved audio channels
    ]

    /// A date formatter for creating unique file names.
    private let dateFormatter = DateFormatter()

    /// The base folder for the file(s) to write audio to.
    private var fileFolder: URL?

    enum AudioFileType: String {
        case system
        case mic
        case merged
    }

    /// The latest part number for the audio file.
    private var latestPart: Int = 0

    /// The latest stream configuration.
    private var configuration: SCStreamConfiguration?

    /// The latest content filter.
    private var filter: SCContentFilter?

    /// So what this does is it creates a URL for the audio file based on the type and part number.
    /// For example, if you want to create a URL for the system audio file, you would call `audioFileURL(for: .system)`.
    /// If you want to create a URL for the second part of the system audio file, you would call `audioFileURL(for: .system, part: 2)`.
    /// That would return a URL for the file `system_2.aiff` in the fileFolder.
    /// - Parameters:
    ///   - type: The type of audio file to create a URL for.
    ///   - part: The part number of the audio file. Defaults to latest based on whats in the folder. -1 means no part number.
    private func audioFileURL(for type: AudioFileType, part: Int? = nil) -> URL? {
        guard let fileFolder else { return nil }

        // If part is nil, use our tracked latest part number.
        let part = part ?? latestPart
        let partString = part >= 0 ? "_\(part)" : ""
        let fileString = "\(type.rawValue)\(partString)"
        let file = fileFolder.appendingPathComponent(fileString)
        if part >= 0 {
            return file.appendingPathExtension("aiff")
        } else {
            return file.appendingPathExtension("m4a")
        }
    }

    /// Returns an array of URLs for audio files of the specified type.
    /// Fairly naive implementation, but it works for our use case.
    private func audioFilesOfType(_ type: AudioFileType) -> [URL] {
        guard let fileFolder else { return [] }
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: fileFolder, includingPropertiesForKeys: nil, options: [])
        return fileURLs?.filter { $0.lastPathComponent.contains(type.rawValue) } ?? []
    }

    override init() {
        super.init()
        dateFormatter.dateFormat = "MMM_dd_yyyy_HH_mm_ss"
    }

    /// - Tag: StartCapture
    func startCapture(
        configuration: SCStreamConfiguration,
        filter: SCContentFilter
    ) -> AsyncThrowingStream<String, Error> { AsyncThrowingStream<String, Error> { continuation in
        latestPart = 0
        self.configuration = configuration
        self.filter = filter
        // The stream output object. Avoid reassigning it to a new object every time startCapture is called.
        let streamOutput = CaptureEngineStreamOutput(continuation: continuation)
        self.streamOutput = streamOutput

        // Create directory for audio files
        fileFolder = AudioFileWriter.audioDir.appendingPathComponent(dateFormatter.string(from: Date()))
        guard let fileFolder else {
            continuation.finish(throwing: CaptureError.invalidURL)
            return
        }
        try? FileManager.default.createDirectory(at: fileFolder, withIntermediateDirectories: true, attributes: nil)

        guard let systemFileURL = self.audioFileURL(for: .system), let micFileURL = self.audioFileURL(for: .mic) else {
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
            logger.error("Error starting capture: \(error)")
            continuation.finish(throwing: error)
        }
    } }

    func stopCapture() async {
        latestPart = 0
        do {
            try await stream?.stopCapture()
            audioRecorder?.stop()
            audioRecorder = nil

            await streamOutput?.audioFileWriter?.finishWriting()

            // Merge audio files after writing is finished
            self.streamOutput?.audioFileWriter = nil

            do {
                // First ensure that the audio files URLs are valid
                guard let systemFileURL = self.audioFileURL(for: .system, part: -1),
                      let micFileURL = self.audioFileURL(for: .mic, part: -1),
                      let mergedFileURL = self.audioFileURL(for: .merged, part: -1)
                else {
                    self.logger.error("Invalid audio file URLs")
                    AlertManager.shared.doShowAlert(
                        title: "Error",
                        message: "Invalid audio file URLs. If this error persists, please contact support."
                    )
                    return
                }

                // Join the audio files into one for each type, sequentially
                let typesToJoin: [AudioFileType] = [.system, .mic]
                for type in typesToJoin.sorted(by: { $0.rawValue < $1.rawValue }) {
                    let fileURLs = audioFilesOfType(type)
                    let joinedAudioFileURL = audioFileURL(for: type, part: -1)

                    guard let joinedAudioFileURL else {
                        self.logger.error("Invalid joined audio file URL for \(type.rawValue)")
                        AlertManager.shared.doShowAlert(
                            title: "Error",
                            message: "Invalid merged audio file URL. If this error persists, please contact support."
                        )
                        return
                    }

                    self.logger.info("Joining \(fileURLs.count) audio files of type \(type.rawValue) into \(joinedAudioFileURL.lastPathComponent)")
                    try await joinAudioFiles(fileURLs: fileURLs, outputURL: joinedAudioFileURL)
                }

                // Now overlay the system and mic audio files to create the final audio file
                try await self.overlayAudioFiles(audioFileURLs: [systemFileURL, micFileURL], outputURL: mergedFileURL)

                // Now send it to the chat
                MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).handleFile(url: mergedFileURL)

                // // Now delete the raw audio files
                // for type in typesToMerge {
                //     let fileURLs = audioFilesOfType(type)
                //     for fileURL in fileURLs {
                //         try? FileManager.default.removeItem(at: fileURL)
                //     }
                // }
            } catch {
                self.logger.error("Error merging audio files: \(error)")
                AlertManager.shared.doShowAlert(
                    title: "Error",
                    message: "Error merging audio files: \(error.localizedDescription). If this error persists, please contact support."
                )
            }

            continuation?.finish()
        } catch {
            logger.error("Error stopping capture: \(error)")
            continuation?.finish(throwing: error)
        }
    }

    /// Allow pausing the capture session.
    /// We essentially stop the capture session, but keep store the latest part number so we can resume it later.
    func pauseCapture() async {
        logger.info("Pausing capture for \(self.fileFolder?.lastPathComponent ?? "nil")")
        latestPart += 1

        do {
            try await stream?.stopCapture()
            audioRecorder?.stop()
            audioRecorder = nil

            await streamOutput?.audioFileWriter?.finishWriting()
            self.streamOutput?.audioFileWriter = nil

            continuation?.finish()
        } catch {
            logger.error("Error pausing capture: \(error)")
            continuation?.finish(throwing: error)
        }
    }

    func resumeCapture() -> AsyncThrowingStream<String, Error> { AsyncThrowingStream<String, Error> { continuation in
        guard let configuration = self.configuration,
              let filter = self.filter,
              let fileFolder = self.fileFolder
        else {
            continuation.finish(throwing: CaptureError.invalidURL)
            return
        }
        logger.info("Resuming capture for \(fileFolder.lastPathComponent)")

        // The stream output object. Avoid reassigning it to a new object every time startCapture is called.
        let streamOutput = CaptureEngineStreamOutput(continuation: continuation)
        self.streamOutput = streamOutput

        // Validate the file folder exists
        guard FileManager.default.fileExists(atPath: fileFolder.path) else {
            continuation.finish(throwing: CaptureError.invalidURL)
            logger.error("File folder does not exist: \(fileFolder.path)")
            return
        }

        guard let systemFileURL = self.audioFileURL(for: .system), let micFileURL = self.audioFileURL(for: .mic) else {
            continuation.finish(throwing: CaptureError.invalidURL)
            logger.error("Invalid audio file URLs")
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
            logger.error("Error resuming capture: \(error)")
            continuation.finish(throwing: error)
        }
    } }

    /// - Tag: UpdateStreamConfiguration
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
        }
    }
}

/// - Tag: Audio file manipulation
extension CaptureEngine {
    func joinAudioFiles(fileURLs: [URL], outputURL: URL) async throws {
        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw CaptureError.createTrackFailed
        }

        for fileURL in fileURLs {
            let asset = AVURLAsset(url: fileURL)

            // Load tracks asynchronously
            try await asset.loadTracks(withMediaType: .audio)
            guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }

            // Load duration
            let duration = try await asset.load(.duration)

            do {
                try track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration),
                                          of: assetTrack,
                                          at: composition.duration)
            } catch {
                // Handle error
                print("Error inserting time range: \(error)")
            }
        }

        // Configure and start the export session
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw CaptureError.exportFailed
        }
        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a

        // Perform the export asynchronously
        await exporter.export()
    }

    /// Merges multiple audio files into one by overlaying them.
    func overlayAudioFiles(audioFileURLs: [URL], outputURL: URL) async throws {
        let composition = AVMutableComposition()

        // Ensure there are two audio files to overlay
        guard audioFileURLs.count == 2 else { return }

        // Attempt to create tracks in the composition for each audio file
        var tracks: [AVMutableCompositionTrack] = []

        // Create the appropriate number of tracks for the audio files
        for _ in audioFileURLs {
            guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw CaptureError.createTrackFailed
            }
            tracks.append(track)
        }

        for (index, fileURL) in audioFileURLs.enumerated() {
            let asset = AVURLAsset(url: fileURL)

            // Choose the correct track for the current file
            let track = tracks[index]

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
