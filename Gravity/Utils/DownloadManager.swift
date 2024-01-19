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

    private(set) var state: DownloadState = .notStarted {
        didSet {
            let ourself = self
            logger.debug("Download state changed to \(ourself.state.description)")
        }
    }

    func downloadModel(from url: URL, to destinationURL: URL, expectedHash: String) {
        state = .downloading

        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            guard let self else { return }

            if let error {
                state = .failed(error)
                return
            }

            guard let localURL else {
                state = .failed(DownloadError.invalidLocalURL)
                return
            }

            state = .verifying
            if verifyDownload(fileURL: localURL, expectedHash: expectedHash) {
                moveFile(from: localURL, to: destinationURL)
                state = .completed
            } else {
                state = .failed(DownloadError.hashMismatch)
            }
        }

        task.resume()
    }

    private func moveFile(from url: URL, to destinationURL: URL) {
        do {
            try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: url, to: destinationURL)
        } catch {
            state = .failed(error)
        }
    }

    private func verifyDownload(fileURL: URL, expectedHash: String) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: data)

            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            return hashString == expectedHash
        } catch {
            print("Error reading file for hash verification: \(error)")
            return false
        }
    }

    enum DownloadError: Error {
        case invalidLocalURL
        case hashMismatch
    }
}
