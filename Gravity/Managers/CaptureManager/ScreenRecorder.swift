/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A model object that provides the interface to capture screen content and system audio.
 */
import Combine
import Foundation
import OSLog
import ScreenCaptureKit
import SwiftUI

/// A provider of audio levels from the captured samples.
class AudioLevelsProvider: ObservableObject {
    @Published var audioLevels = AudioLevels.zero
}

@MainActor
class ScreenRecorder: NSObject,
    ObservableObject
{
    private let logger = Logger()

    public static let shared = ScreenRecorder()

    override private init() {
        super.init()
    }

    @Published var isRunning = false

    // MARK: - Video Properties

    @Published var selectedDisplay: SCDisplay? {
        didSet { updateEngine() }
    }

    @Published var isAppExcluded = true {
        didSet { updateEngine() }
    }

    private var availableApps = [SCRunningApplication]()
    @Published private(set) var availableDisplays = [SCDisplay]()

    // MARK: - Audio Properties

    @Published var isAudioCaptureEnabled = true {
        didSet {
            updateEngine()
            if isAudioCaptureEnabled {
                startAudioMetering()
            } else {
                stopAudioMetering()
            }
        }
    }

    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    // A value that specifies how often to retrieve calculated audio levels.
    private let audioLevelRefreshRate: TimeInterval = 0.1
    private var audioMeterCancellable: AnyCancellable?

    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()

    private var isSetup = false

    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have screen recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                // Only audio
                // try await SCShareableContent.
                return true
            } catch {
                return false
            }
        }
    }

    func monitorAvailableContent() async {
        guard !isSetup else { return }
        // Refresh the lists of capturable content.
        await self.refreshAvailableContent()
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            Task {
                await self.refreshAvailableContent()
            }
        }
        .store(in: &subscriptions)
    }

    /// Starts capturing screen content.
    func start() async {
        // Exit early if already running.
        guard !isRunning else { return }

        if !isSetup {
            // Starting polling for available screen content.
            await monitorAvailableContent()
            isSetup = true
        }

        // If the user enables audio capture, start monitoring the audio stream.
        if isAudioCaptureEnabled {
            startAudioMetering()
        }

        do {
            let config = streamConfiguration
            let filter = contentFilter
            // Update the running state.
            isRunning = true
            // Start the stream and await new video frames.
            for try await frame in captureEngine.startCapture(configuration: config, filter: filter) {
                // capturePreview.updateFrame(frame)
                print(frame)
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            // Unable to start the stream. Set the running state to false.
            isRunning = false
        }
    }

    /// Stops capturing screen content.
    func stop() async {
        guard isRunning else { return }
        await captureEngine.stopCapture()
        stopAudioMetering()
        isRunning = false
    }

    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            self.audioLevelsProvider.audioLevels = self.captureEngine.audioLevels
        }
    }

    private func stopAudioMetering() {
        audioMeterCancellable?.cancel()
        audioLevelsProvider.audioLevels = AudioLevels.zero
    }

    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            let filter = contentFilter
            await captureEngine.update(configuration: streamConfiguration, filter: filter)
        }
    }

    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            availableDisplays = availableContent.displays

            availableApps = availableContent.applications

            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }

    private var contentFilter: SCContentFilter {
        var filter: SCContentFilter

        guard let display = selectedDisplay else { fatalError("No display selected.") }

        var excludedApps = [SCRunningApplication]()
        // If a user chooses to exclude the app from the stream,
        // exclude it by matching its bundle identifier.
        if isAppExcluded {
            excludedApps = availableApps.filter { app in
                Bundle.main.bundleIdentifier == app.bundleIdentifier
            }
        }
        // Create a content filter with excluded apps.
        filter = SCContentFilter(display: display,
                                 excludingApplications: excludedApps,
                                 exceptingWindows: [])

        return filter
    }

    private var streamConfiguration: SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()

        // Configure audio capture.
        streamConfig.capturesAudio = isAudioCaptureEnabled
        streamConfig.excludesCurrentProcessAudio = false

        // Configure the display content width and height.
        if let display = selectedDisplay {
            streamConfig.width = display.width
            streamConfig.height = display.height
        }

        // Set the capture interval at 1 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5

        return streamConfig
    }
}
