//
//  LLMManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import DockProgress
import Foundation
import LLM
import OSLog
import SwiftUI

final class LLMManager {
    private let logger = Logger(subsystem: "ai.grav.app", category: "LLMManager")

    static let shared = LLMManager()

    public let downloadManager: FileDownloader = FileDownloader(reportDockProgress: true)
    private let modelInfo = ModelRepository.MISTRAL_7B_V2_Q4
    private var downloadRetries = 0

    private var _llm: LLM?
    public var llm: LLM? {
        get async {
            // If the model is already completed but deinited, reload it
            if downloadManager.state == .completed {
                loadLLM()
            }
            while _llm == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                // Only increment retries if we have already tried to download the model
                if downloadManager.state == .failed, downloadRetries < 100 {
                    downloadRetries += 1
                    logger.debug("Waiting for \(self.modelInfo.name) to be ready (\(self.downloadRetries))")
                    await setup()
                }
            }
            return _llm
        }
    }

    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("maxContextLength") private var maxContextLength: Double = 4000

    private init() {}

    @MainActor
    func chat(
        messages: [Message],
        // Default processOutput function, just appends the output to a variable and returns it
        processOutput: @escaping (AsyncStream<String>) async -> String = { stream in
            var result = ""
            for await line in stream {
                // Default processing (e.g., simply appending the line)
                result += line
            }
            return result
        }
    ) async {
        do {
            try await llm?.waitUntilAvailable(timeout: .now() + 20)
        } catch {
            logger.error("Error waiting for LLM to be available: \(error)")
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Error waiting for LLM to be available: \(error)"
            )
            return
        }

        // Wrap the processOutput function to capture the output in a variable that we can return
        let processOutputWrapped = { (stream: AsyncStream<String>) async -> String in
            let result = await processOutput(stream)

            // Deinit the LLM to free up memory TODO: actually determine if this is a good idea
            self.logger.debug("Deiniting LLM")
            self._llm = nil
            return result
        }

        let history = messages.map { message in
            if message.role == .assistant {
                (Role.bot, message.text)
            } else {
                (Role.user, message.text)
            }
        }

        await llm?.respond(to: history, with: processOutputWrapped)
    }

    @MainActor
    func achat(messages: [Message]) async -> Message {
        do {
            try await llm?.waitUntilAvailable(timeout: .now() + 20)
        } catch {
            logger.error("Error waiting for LLM to be available: \(error)")
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Error waiting for LLM to be available: \(error)"
            )
        }

        let history = messages.map { message in
            if message.role == .assistant {
                (Role.bot, message.text)
            } else {
                (Role.user, message.text)
            }
        }

        let output = await llm?.respond(to: history)

        // Deinit the LLM to free up memory
        self.logger.debug("Deiniting LLM")
        _llm = nil
        return Message(content: output, role: .assistant)
    }

    func setup() async {
        if downloadManager.verifyFile(
            at: modelInfo.localURL,
            expectedHash: modelInfo.hash
        ) {
            logger.debug("Verified and Loading \(self.modelInfo.name) at \(self.modelInfo.localURL)")
            loadLLM()
        } else {
            logger.debug("Downloading \(self.modelInfo.name) from \(self.modelInfo.url)")
            do {
                try await downloadManager.download(
                    from: modelInfo.url,
                    to: modelInfo.localURL,
                    expectedHash: modelInfo.hash
                )

                logger.debug("Loading \(self.modelInfo.name) from \(self.modelInfo.localURL)")
                loadLLM()
            } catch {
                logger.error("Could not download \(self.modelInfo.name): \(error)")
            }
        }
    }

    func loadLLM() {
        let template = Template.mistral

        // _llm = LLM(from: modelInfo.localURL, template: template, topP: 0.3, temp: 0.9)
        // _llm = LLM(from: modelInfo.localURL, template: template, topP: 0.95, temp: 0.7, maxTokenCount: 4096)
        _llm = LLM(from: modelInfo.localURL, template: template, topP: 0.95, temp: Float(temperature), maxTokenCount: Int32(maxContextLength))
    }

    func wipe() {
        try? FileManager.default.removeItem(at: modelInfo.localURL)
    }
}
