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

final class LLMManager: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "LLMManager")

    static let shared = LLMManager()

    private var downloadRetries = 0
    @Published public var modelFileManager: ModelFileManager = ModelFileManager(modelInfo: ModelRepository.OpenHermes_2_5_Mistral_7B, reportDockProgress: true)

    private var _llm: LLM?
    public var llm: LLM? {
        get async {
            while _llm == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                // Only increment retries if we have already tried to download the model
                if modelFileManager.state == .failed, downloadRetries < 100 {
                    downloadRetries += 1
                    logger.debug("Waiting for \(self.modelFileManager.modelInfo.name) to be ready (\(self.downloadRetries))")
                    await setup()
                }
            }
            return _llm
        }
    }

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
            await llm?.stop()
            await llm?.setNewSeed()
            return
        }

        // Wrap the processOutput function to capture the output in a variable that we can return
        let processOutputWrapped = { (stream: AsyncStream<String>) async -> String in
            let result = await processOutput(stream)
            return result
        }

        // For audio messages, chunk the input and summarize each chunk
        for message in messages {
            if message.audio != nil, message.summarizedChunks.count == 0, await llm?.numTokens(message.text) ?? 0 > 1024 {
                await message.generateSummarizedChunks()
            }
        }

        let history = messages.map { message in
            if message.role == .assistant {
                (ChatRole.bot, message.text)
            } else {
                (ChatRole.user, message.text)
            }
        }

        await llm?.respond(to: history, with: processOutputWrapped)
    }

    // @MainActor
    func achat(messages: [Message]) async -> Message {
        do {
            try await llm?.waitUntilAvailable(timeout: .now() + 20)
        } catch {
            logger.error("Error waiting for LLM to be available: \(error)")
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Error waiting for LLM to be available: \(error)"
            )
            await llm?.stop()
            await llm?.setNewSeed()
        }

        let history = messages.map { message in
            if message.role == .assistant {
                (ChatRole.bot, message.text)
            } else {
                (ChatRole.user, message.text)
            }
        }

        let output = await llm?.arespond(to: history)

        return Message(content: output, role: .assistant)
    }

    func setup() async {
        if modelFileManager.verifyFile(
            at: modelFileManager.modelInfo.localURL,
            expectedHash: modelFileManager.modelInfo.sha256
        ) {
            logger.debug("Verified and Loading \(self.modelFileManager.modelInfo.name) at \(self.modelFileManager.modelInfo.localURL)")
            load()
        } else {
            logger.debug("Downloading \(self.modelFileManager.modelInfo.name) from \(self.modelFileManager.modelInfo.url)")
            do {
                try await modelFileManager.download()

                logger.debug("Loading \(self.modelFileManager.modelInfo.name) from \(self.modelFileManager.modelInfo.localURL)")
                load()
            } catch {
                logger.error("Could not download \(self.modelFileManager.modelInfo.name): \(error)")
                AlertManager.shared.doShowAlert(
                    title: "Error",
                    message: "Could not download \(self.modelFileManager.modelInfo.name): \(error.localizedDescription)"
                )
            }
        }
    }

    func load() {
        let template = Template.chatML()
        _llm = LLM(from: modelFileManager.modelInfo.localURL, template: template, topK: 40, topP: 0.9, temp: 0.8, maxTokenCount: 2048)
    }

    func wipe() {
        try? FileManager.default.removeItem(at: modelFileManager.modelInfo.localURL)
    }
}
