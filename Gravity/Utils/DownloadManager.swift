//
//  DownloadManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/19/24.
//

import CryptoKit
import Foundation
import os

class DownloadManager {
    private let logger = Logger(subsystem: "ai.grav.app", category: "DownloadManager")

    static let gravityHomeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gravity")

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

    private(set) var state: DownloadState = .notStarted {
        didSet {
            logger.debug("Download state changed to \(self.state.description)")
        }
    }

    var lastError: Error?

    /// Downloads a file from a given URL to a given destination URL, verifying the SHA256 hash of the file
    func download(from url: URL, to destinationURL: URL, expectedHash: String) async throws {
        state = .downloading
        lastError = nil

        let localURL: URL = try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
                if let error {
                    continuation.resume(throwing: DownloadError.downloadFailed(error))
                    self.state = .failed
                    self.lastError = error
                    return
                }
                guard let localURL else {
                    continuation.resume(throwing: DownloadError.invalidLocalURL)
                    self.state = .failed
                    self.lastError = error
                    return
                }
                continuation.resume(returning: localURL)
            }
            task.resume()
        }

        state = .verifying
        if verifyFile(at: localURL, expectedHash: expectedHash) {
            do {
                try moveFile(from: localURL, to: destinationURL)
                state = .completed
            } catch {
                state = .failed
                lastError = error
            }
        } else {
            throw DownloadError.hashMismatch
        }
    }

    /// Moves a file from one URL to another
    private func moveFile(from url: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: url, to: destinationURL)
    }

    /// Verifies the SHA256 hash of a file at a given URL
    func verifyFile(at fileURL: URL, expectedHash: String) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: data)

            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            return hashString == expectedHash
        } catch {
            logger.error("Error reading file for hash verification: \(error)")
            return false
        }
    }
}
