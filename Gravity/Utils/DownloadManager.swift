//
//  DownloadManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/19/24.
//

import Combine
import CryptoKit
import DockProgress
import Foundation
import os

class DownloadManager: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "DownloadManager")

    static let gravityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gravity")

    enum DownloadState: CustomStringConvertible {
        case notStarted
        case downloading
        case verifying
        case verified
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
            case .verified:
                "Verified"
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
            logger.debug("Download state changed to \(self.state.description)")
        }
    }

    @Published var progress: Double = 0.0

    private var cancellables: Set<AnyCancellable> = []
    private let reportDockProgress: Bool

    init(reportDockProgress: Bool = false) {
        self.reportDockProgress = reportDockProgress
    }

    /// Downloads a file from a given URL to a given destination URL, verifying the SHA256 hash of the file
    func download(from url: URL, to destinationURL: URL, expectedHash: String) async throws {
        DispatchQueue.main.async {
            self.state = .downloading
        }

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        try await withCheckedThrowingContinuation { [unowned self] (continuation: CheckedContinuation<Void, Error>) in
            let task = session.downloadTask(with: url) { localURL, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let localURL else {
                    continuation.resume(throwing: DownloadError.invalidLocalURL)
                    return
                }

                // Post-download verification and processing can be done here
                if self.verifyFile(at: localURL, expectedHash: expectedHash) {
                    do {
                        try self.moveFile(from: localURL, to: destinationURL)
                        DispatchQueue.main.async {
                            self.state = .completed
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.state = .failed
                        }
                        self.logger.error("Error moving file: \(error)")
                    }
                } else {
                    self.logger.error("Hash mismatch")
                }
                continuation.resume(returning: ())
            }

            task.progress.publisher(for: \.fractionCompleted)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] progress in
                    // Only update progress if it's gone up
                    if progress > self?.progress ?? 0.0 {
                        self?.progress = progress
                        self?.logger.debug("Download progress: \(progress)")

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
            DispatchQueue.main.async {
                self.state = .verified
            }
            return hashString == expectedHash
        } catch {
            logger.error("Error reading file for hash verification: \(error)")
            return false
        }
    }
}
