//
//  FileDownloader.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/19/24.
//

import Combine
import CryptoKit
import DockProgress
import Foundation
import OSLog

class ModelFileManager: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "DownloadManager")

    enum DownloadState: CustomStringConvertible {
        case notStarted
        case downloading
        case verifying
        case completed
        case failed

        var description: String {
            switch self {
            case .notStarted:
                "Not Started"
            case .downloading:
                "Downloading"
            case .verifying:
                "Verifying"
            case .completed:
                "Completed"
            case .failed:
                "Failed"
            }
        }
    }

    enum DownloadError: Error {
        case invalidLocalURL
        case hashMismatch
        case downloadFailed(Error)
    }

    @Published private(set) var state: DownloadState = .notStarted {
        didSet {
            logger.debug("Download state changed to \(self.state.description) for \(self.modelInfo.name)")
        }
    }

    @Published var progress: Double = 0.0

    private var cancellables: Set<AnyCancellable> = []
    private let reportDockProgress: Bool

    private let modelInfo: ModelInfo

    init(modelInfo: ModelInfo, reportDockProgress: Bool = false) {
        self.modelInfo = modelInfo
        self.reportDockProgress = reportDockProgress
    }

    /// Downloads a file from a given URL to a given destination URL, verifying the SHA256 hash of the file
    func download() async throws {
        DispatchQueue.main.async {
            self.state = .downloading
        }

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        try await withCheckedThrowingContinuation { [unowned self] (continuation: CheckedContinuation<Void, Error>) in
            let task = session.downloadTask(with: self.modelInfo.url) { localURL, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let localURL else {
                    continuation.resume(throwing: DownloadError.invalidLocalURL)
                    return
                }

                // Post-download verification and processing can be done here
                if self.verifyFile(at: localURL, expectedHash: self.modelInfo.hash) {
                    do {
                        try self.moveFile(from: localURL, to: self.modelInfo.localURL)
                        DispatchQueue.main.async {
                            self.state = .completed
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.state = .failed
                        }
                        self.logger.error("Error moving file for \(self.modelInfo.name): \(error)")
                    }
                } else {
                    self.logger.error("Hash mismatch for \(self.modelInfo.name)")
                }
                continuation.resume(returning: ())
            }

            task.progress.publisher(for: \.fractionCompleted)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] progress in
                    // Only update progress if it's gone up
                    if progress > self?.progress ?? 0.0 {
                        self?.progress = progress
                        self?.logger.debug("Download progress for \(self?.modelInfo.name ?? ""): \(progress)")

                        // And only report progress to Dock if we're supposed to, to avoid flickering
                        if self?.reportDockProgress ?? false {
                            DispatchQueue.main.async {
                                DockProgress.progress = progress
                            }
                        }
                    }
                })
                .store(in: &self.cancellables)

            task.resume()
        }
    }

    /// Moves a file from one URL to another
    private func moveFile(from url: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: url, to: destinationURL)
    }

    /// Verifies the SHA256 hash of a file at a given URL
    func verifyFile(at fileURL: URL, expectedHash: String) -> Bool {
        DispatchQueue.main.async {
            self.state = .verifying
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: data)

            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

            if hashString == expectedHash {
                logger.debug("Hash verification successful for \(self.modelInfo.name)")

                DispatchQueue.main.async {
                    self.state = .completed
                }
                return true
            } else {
                logger.error("Hash verification failed for \(self.modelInfo.name)")
                return false
            }
        } catch {
            logger.error("Error reading file for hash \(self.modelInfo.name) verification: \(error)")
            return false
        }
    }
}
