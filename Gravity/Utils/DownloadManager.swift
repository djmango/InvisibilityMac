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
        case failed(Error)

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
            case let .failed(error):
                "Failed: \(error.localizedDescription)"
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
            let ourself = self
            logger.debug("Download state changed to \(ourself.state.description)")
        }
    }

    func download(from url: URL, to destinationURL: URL, expectedHash: String) async throws {
        state = .downloading

        let localURL: URL = try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
                if let error {
                    continuation.resume(throwing: DownloadError.downloadFailed(error))
                    return
                }
                guard let localURL else {
                    continuation.resume(throwing: DownloadError.invalidLocalURL)
                    return
                }
                continuation.resume(returning: localURL)
            }
            task.resume()
        }

        state = .verifying
        if verifyDownload(fileURL: localURL, expectedHash: expectedHash) {
            do {
                try moveFile(from: localURL, to: destinationURL)
                state = .completed
            } catch {
                state = .failed(error)
            }
        } else {
            throw DownloadError.hashMismatch
        }
    }

    private func moveFile(from url: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: url, to: destinationURL)
    }

    private func verifyDownload(fileURL: URL, expectedHash: String) -> Bool {
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
