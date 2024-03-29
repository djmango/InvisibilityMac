//
//  ScreenRecorder.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import ScreenCaptureKit
import SwiftUI

/// A class that manages screen recording. Primarily audio at the moment.
final class ScreenRecorder: NSObject, ObservableObject {
    private let logger = Logger()

    public static let shared = ScreenRecorder()

    override private init() {
        super.init()
    }

    @Published var isRunning = false

    // MARK: - Video Properties

    var selectedDisplay: SCDisplay? {
        didSet { updateEngine() }
    }

    var isAppExcluded = true {
        didSet { updateEngine() }
    }

    private var availableApps = [SCRunningApplication]()
    private(set) var availableDisplays = [SCDisplay]()

    // MARK: - Audio Properties

    var isAudioCaptureEnabled = true {
        didSet {
            updateEngine()
        }
    }

    // A value that specifies how often to retrieve calculated audio levels.
    private let audioLevelRefreshRate: TimeInterval = 0.1
    private var audioMeterCancellable: AnyCancellable?

    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()

    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have screen recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }

    var canRecordMic: Bool {
        get async {
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    self?.logger.debug("Audio permission granted: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func askForScreenRecordingPermission() async -> Bool {
        guard await canRecord else {
            if OnboardingManager.shared.onboardingViewed {
                AlertManager.shared.doShowAlert(title: "Screen Recording Permission Grant", message: "Invisibility has not been granted permission to record the screen. Please enable this permission in System Preferences > Security & Privacy > Screen & System Audio Recording.")
            }
            // Open the System Preferences app to the Screen Recording settings.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
            return false
        }
        logger.debug("Screen recording permission granted.")
        return true
    }

    /// Starts capturing screen content.
    @MainActor
    func start() async {
        // Exit early if already running.
        guard !isRunning else { return }
        guard await canRecord else {
            AlertManager.shared.doShowAlert(title: "Screen Recording Permission Grant", message: "Invisibility has not been granted permission to record the screen. Please enable this permission in System Preferences > Security & Privacy > Screen & System Audio Recording.")
            // Open the System Preferences app to the Screen Recording settings.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        guard await canRecordMic else {
            AlertManager.shared.doShowAlert(title: "Microphone Permission Grant", message: "Invisibility has not been granted permission to record the microphone. Please enable this permission in System Preferences > Security & Privacy > Microphone.")
            // Open the System Preferences app to the Microphone settings.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
            return
        }

        // Refresh the available content to capture.
        await refreshAvailableContent()

        // Start the stream and await new video frames.
        isRunning = true
        let _ = captureEngine.startCapture(configuration: streamConfiguration, filter: contentFilter)
    }

    /// Stops capturing screen content.
    @MainActor
    func stop() async {
        guard isRunning else { return }
        await captureEngine.stopCapture()
        isRunning = false
    }

    @MainActor
    func pause() async -> Bool {
        guard isRunning else { return false }
        await captureEngine.pauseCapture()
        isRunning = false
        return true
    }

    @MainActor
    func resume() async {
        guard !isRunning else { return }
        let _ = captureEngine.resumeCapture()
        isRunning = true
    }

    @MainActor
    func toggleRecording() {
        if isRunning {
            Task {
                await stop()
            }
        } else {
            Task {
                await start()
            }
        }
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
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
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
        filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

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

        return streamConfig
    }
}
