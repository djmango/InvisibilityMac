/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A model object that provides the interface to capture screen content and system audio.
 */
import Combine
import Foundation
import OSLog
import PostHog
import ScreenCaptureKit
import SwiftUI

@MainActor
class ScreenRecorder: NSObject,
    ObservableObject,
    SCContentSharingPickerObserver
{
    static let shared = ScreenRecorder()

    override private init() {
        super.init()
    }

    /// The supported capture types.
    enum CaptureType {
        case display
        case window
    }

    // private let logger = Logger()

    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "ScreenRecorder")

    @Published var isRunning = false

    // MARK: - Video Properties

    @Published var captureType: CaptureType = .display {
        didSet { updateEngine() }
    }

    @Published var selectedDisplay: SCDisplay? {
        didSet { updateEngine() }
    }

    @Published var selectedWindow: SCWindow? {
        didSet { updateEngine() }
    }

    let isAppExcluded = true
    // {
    //     didSet { updateEngine() }
    // }

    // MARK: - SCContentSharingPicker Properties

    @Published var maximumStreamCount = Int() {
        didSet { updatePickerConfiguration() }
    }

    @Published var excludedWindowIDsSelection = Set<Int>() {
        didSet { updatePickerConfiguration() }
    }

    @Published var excludedBundleIDsList = [String]() {
        didSet { updatePickerConfiguration() }
    }

    let allowsRepicking = true
    // {
    //     didSet { updatePickerConfiguration() }
    // }

    @Published var allowedPickingModes = SCContentSharingPickerMode() {
        didSet { updatePickerConfiguration() }
    }

    @Published var contentSize = CGSize(width: 1, height: 1)
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }

    /// A view that renders the screen content.
    lazy var capturePreview: CapturePreview = CapturePreview()

    private let screenRecorderPicker = SCContentSharingPicker.shared
    private var availableApps = [SCRunningApplication]()
    private(set) var availableDisplays = [SCDisplay]()
    private(set) var availableWindows = [SCWindow]()
    @Published private(set) var pickerUpdate: Bool = false // Update the running stream immediately with picker selection
    private var pickerContentFilter: SCContentFilter?
    private var shouldUsePickerFilter = true
    /// - Tag: TogglePicker
    @Published var isPickerActive = false {
        didSet {
            if isPickerActive {
                logger.info("Picker is active")
                self.initializePickerConfiguration()
                self.screenRecorderPicker.isActive = true
                self.screenRecorderPicker.add(self)
            } else {
                logger.info("Picker is inactive")
                self.screenRecorderPicker.isActive = false
                self.screenRecorderPicker.remove(self)
            }
        }
    }

    // MARK: - Audio Properties

    @Published var isAudioCaptureEnabled = false {
        didSet {
            updateEngine()
        }
    }

    @Published var isAppAudioExcluded = false { didSet { updateEngine() } }
    // A value that specifies how often to retrieve calculated audio levels.
    private let audioLevelRefreshRate: TimeInterval = 0.1
    private var audioMeterCancellable: AnyCancellable?

    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()

    private var isSetup = false

    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    private var videoWriter: VideoWriter = VideoWriter()
    private let videoWriterQueue = DispatchQueue(label: "videowriter.queue")

    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have screen recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }

    func monitorAvailableContent() async {
        guard !isSetup || !isPickerActive else { return }
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

    /// Starts capturing screen content.
    func start() async {
        defer { PostHogSDK.shared.capture("start_recording") }
        // Exit early if already running.
        guard !isRunning else { return }
        guard await canRecord else {
            _ = await ScreenshotManager.shared.askForScreenRecordingPermission()
            return
        }

        if !isSetup {
            // Starting polling for available screen content.
            await monitorAvailableContent()
            isSetup = true
        }

        do {
            let config = streamConfiguration
            let filter = contentFilter
            // Update the running state.
            withAnimation(AppConfig.snappy) {
                isRunning = true
            }
            setPickerUpdate(false)
            isPickerActive = true

            // Set up the video writer to record the video
            let frameSize = CGSize(width: config.width, height: config.height)
            videoWriter.frameSize = frameSize
            
            var frameIndex: Int64 = 0
            
            // Start the stream and await new video frames.
            for try await frame in self.captureEngine.startCapture(configuration: config, filter: filter) {
                self.capturePreview.updateFrame(frame)
                if self.contentSize != frame.size {
                    // Update the content size if it changed.
                    self.contentSize = frame.size
                }

                videoWriterQueue.async {
                    if (frameIndex % Int64(60/self.videoWriter.fps) == 0) {
                        if let image = self.getCurrentFrameAsCGImage() {
                            self.videoWriter.recordFrame(frame: image)
                        }
                    }
                }
                
                frameIndex += 1
            }
        } catch {
            self.logger.error("\(error.localizedDescription)")
            // Unable to start the stream. Set the running state to false.
            withAnimation(AppConfig.snappy) {
                self.isRunning = false
            }
        }
    }

    /// Stops capturing screen content.
    func stop() async {
        defer { PostHogSDK.shared.capture("stop_recording") }
        guard isRunning else { return }

        videoWriterQueue.async {
            self.videoWriter.sendCurrentClip()
        }
        
        await captureEngine.stopCapture()
        withAnimation(AppConfig.snappy) {
            isRunning = false
        }
        isPickerActive = false
    }

    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            let filter = contentFilter
            await captureEngine.update(configuration: streamConfiguration, filter: filter)
            setPickerUpdate(false)
        }
    }

    // MARK: - Content-sharing Picker

    private func initializePickerConfiguration() {
        var initialConfiguration = SCContentSharingPickerConfiguration()
        // Set the allowedPickerModes from the app.
        initialConfiguration.allowedPickerModes = [
            .singleWindow,
            .multipleWindows,
            .singleApplication,
            .multipleApplications,
            .singleDisplay,
        ]
        self.allowedPickingModes = initialConfiguration.allowedPickerModes
    }

    private func updatePickerConfiguration() {
        self.screenRecorderPicker.maximumStreamCount = maximumStreamCount
        // Update the default picker configuration to pass to Control Center.
        self.screenRecorderPicker.defaultConfiguration = pickerConfiguration
    }

    /// - Tag: HandlePicker
    nonisolated func contentSharingPicker(_: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        logger.info("Picker canceled for stream \(stream)")
    }

    nonisolated func contentSharingPicker(_: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        Task { @MainActor in
            logger.info("Picker updated with filter=\(filter) for stream=\(stream)")
            pickerContentFilter = filter
            shouldUsePickerFilter = true
            setPickerUpdate(true)
            updateEngine()
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        logger.error("Error starting picker! \(error)")
    }

    func setPickerUpdate(_ update: Bool) {
        Task { @MainActor in
            self.pickerUpdate = update
        }
    }

    func presentPicker() {
        if let stream = captureEngine.stream {
            SCContentSharingPicker.shared.present(for: stream)
        } else {
            SCContentSharingPicker.shared.present()
        }
    }

    private var pickerConfiguration: SCContentSharingPickerConfiguration {
        var config = SCContentSharingPickerConfiguration()
        config.allowedPickerModes = allowedPickingModes
        config.excludedWindowIDs = Array(excludedWindowIDsSelection)
        config.excludedBundleIDs = excludedBundleIDsList
        config.allowsChangingSelectedContent = allowsRepicking
        return config
    }

    /// - Tag: UpdateFilter
    private var contentFilter: SCContentFilter {
        var filter: SCContentFilter
        switch captureType {
        case .display:
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
        case .window:
            guard let window = selectedWindow else { fatalError("No window selected.") }

            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        }
        // Use filter from content picker, if active.
        if shouldUsePickerFilter {
            guard let pickerFilter = pickerContentFilter else { return filter }
            filter = pickerFilter
            shouldUsePickerFilter = false
        }
        return filter
    }

    private var streamConfiguration: SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()

        // Configure audio capture.
        streamConfig.capturesAudio = isAudioCaptureEnabled
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded

        // Configure the display content width and height.
        if captureType == .display, let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }

        // Configure the window content width and height.
        if captureType == .window, let window = selectedWindow {
            streamConfig.width = Int(window.frame.width) * 2
            streamConfig.height = Int(window.frame.height) * 2
        }

        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5

        return streamConfig
    }

    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            availableDisplays = availableContent.displays

            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications

            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }

    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
            // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
            // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
            // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
    }

    func getCurrentFrameAsCGImage() -> CGImage? {
        let frame = captureEngine.getCurrentFrame()
        guard let surface = frame.surface else { return nil }

        var pixelBuffer: CVPixelBuffer?
        var pixelBufferAttributes: [NSObject: AnyObject] = [:]
        pixelBufferAttributes[kCVPixelBufferIOSurfacePropertiesKey] = [:] as NSDictionary

        var unmanagedPixelBuffer: Unmanaged<CVPixelBuffer>?
        let status = CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, surface, pixelBufferAttributes as CFDictionary, &unmanagedPixelBuffer)
        pixelBuffer = unmanagedPixelBuffer?.takeRetainedValue()

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    func getCurrentFrameAsURL() -> URL? {
        // Get the current frame as CGImage
        guard let cgImage = getCurrentFrameAsCGImage() else { return nil }

        // Create NSBitmapImageRep from CGImage
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        // Convert to image data (e.g., PNG)
        guard let imageData = bitmapRep.representation(using: .png, properties: [:]) else { return nil }

        // Create temporary file URL
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("captured_frame.png")

        do {
            // Write image data to file
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            logger.error("Error writing image data to file: \(error)")
            return nil
        }
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case let (.some(application), .some(title)):
            "\(application.applicationName): \(title)"
        case let (.none, .some(title)):
            title
        case let (.some(application), .none):
            "\(application.applicationName): \(windowID)"
        default:
            ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}
