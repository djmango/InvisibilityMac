//
//  ScreenshotManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/27/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog
import SwiftUI
import Vision

class ScreenshotManager {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ScreenshotManager")

    static let shared = ScreenshotManager()

    private let messageViewModel: MessageViewModel = MessageViewModel.shared

    var task: Process?
    let sceenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

    lazy var screenShotFilePath: String = {
        let directory = NSTemporaryDirectory()
        return NSURL.fileURL(withPathComponents: [directory, "capture.png"])!.path
    }()

    var screenCaptureArguments: [String] {
        var out = ["-i"] // capture screen interactively, by selection or window
        out.append(screenShotFilePath)
        return out
    }

    private init() {}

    public func capture() async {
        guard await ScreenRecorder.shared.askForScreenRecordingPermission() else { return }

        await WindowManager.shared.hideWindow()
        guard let url = captureImageToURL() else { return }
        await WindowManager.shared.showWindow()
        messageViewModel.handleFile(url)
        try? FileManager.default.removeItem(atPath: screenShotFilePath)
    }

    public func captureTextToClipboard(imagePath: String? = nil) {
        let text = getText(imagePath)
        guard let text else { return }
        precessDetectedText(text)
    }

    public func captureImageToClipboard() {
        guard let image = getImage() else { return }
        // Add it to clipboard
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([image as NSImage])
    }

    public func captureImageToURL() -> URL? {
        task = Process()
        task?.executableURL = sceenCaptureURL

        task?.arguments = screenCaptureArguments

        do {
            try task?.run()
        } catch {
            logger.error("Failed to capture")
            task = nil
            return nil
        }

        task?.waitUntilExit()
        task = nil

        return URL(fileURLWithPath: screenShotFilePath)
    }

    private func getImage(_: String? = nil) -> NSImage? {
        task = Process()
        task?.executableURL = sceenCaptureURL

        task?.arguments = screenCaptureArguments

        do {
            try task?.run()
        } catch {
            logger.error("Failed to capture")
            task = nil
            return nil
        }

        task?.waitUntilExit()
        task = nil
        return NSImage(contentsOfFile: screenShotFilePath)
    }

    private func getText(_ imagePath: String? = nil) -> String? {
        guard task == nil else { return nil }

        guard let image = getImage(imagePath)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let text = parseQR(image: image)
        guard text.isEmpty else {
            return text
        }

        var out: String?
        let group = DispatchGroup()
        group.enter()
        detectText(in: image) { result in
            out = result
            group.leave()
        }
        _ = group.wait(timeout: .now() + 2)
        return out
    }

    func precessDetectedText(_ text: String) {
        defer {
            try? FileManager.default.removeItem(atPath: screenShotFilePath)
        }

        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
        logger.debug("Detected text: \(text)")
    }

    private func detectAndOpenURL(text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        matches?.forEach { match in
            guard let range = Range(match.range, in: text),
                  case let urlStr = String(text[range]),
                  let url = URL(string: urlStr)
            else { return }
            if url.scheme == nil,
               case let urlStr = "https://\(url.absoluteString)",
               let newUrl = URL(string: urlStr)
            {
                NSWorkspace.shared.open(newUrl)
                return
            }
            NSWorkspace.shared.open(url)
        }
    }

    func parseQR(image: CGImage) -> String {
        let image = CIImage(cgImage: image)

        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

        let features = detector?.features(in: image) ?? []

        return features.compactMap { feature in
            (feature as? CIQRCodeFeature)?.messageString
        }.joined(separator: " ")
    }

    func detectText(in image: CGImage, completionHandler: @escaping (String?) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                self.logger.error("Error detecting text: \(error)")
            } else {
                if let result = self.handleDetectionResults(results: request.results) {
                    completionHandler(result)
                }
            }
        }
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate
        // request.customWords = preferences.customWordsList

        performDetection(request: request, image: image)
    }

    private func performDetection(request: VNRecognizeTextRequest, image: CGImage) {
        let requests = [request]

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])

        do {
            try handler.perform(requests)
        } catch {
            print("Error: \(error)")
        }
    }

    private func handleDetectionResults(results: [Any]?) -> String? {
        guard let results, results.count > 0 else {
            return nil
        }

        var output: String = ""
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    // if !output.isEmpty {
                    //     output.append(preferences.ignoreLineBreaks ? " " : "\n")
                    // }
                    output.append(text.string)
                }
            }
        }
        return output
    }
}
