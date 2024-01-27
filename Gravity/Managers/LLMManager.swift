//
//  LLMManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Foundation
import LLM
import os

final class LLMManager {
    private let logger = Logger(subsystem: "ai.grav.app", category: "LLMManager")

    static let shared = LLMManager()

    public let downloadManager: DownloadManager = DownloadManager()
    private let modelInfo = ModelRepository.MISTRAL_7B_V2_Q4

    private var _llm: LLM?
    public var llm: LLM? {
        get async {
            while _llm == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 second

                if downloadManager.state == .failed, downloadRetries < 100 {
                    downloadRetries += 1
                    logger.debug("Waiting for \(self.modelInfo.name) to be ready (\(self.downloadRetries))")
                    await setup()
                }
            }
            return _llm
        }
    }

    /// The model gets loaded asynchronously, so we need to wait for it to be ready
    private var downloadRetries = 0

    var output: String = ""

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
        // Wrap the processOutput function to capture the output in a variable that we can return
        var output = ""
        let processOutputWrapped = { (stream: AsyncStream<String>) async -> String in
            let result = await processOutput(stream)
            output += result
            return result
        }

        var truncatedMessages = messages

        // Add the audio text to the content of messages that have audio
        for (index, message) in truncatedMessages.enumerated() {
            if let audio = message.audio {
                truncatedMessages[index].content = (message.content ?? "") + audio.text
            }
        }

        var totalCharCount = truncatedMessages.reduce(0) { $0 + ($1.content?.count ?? 0) }

        while totalCharCount >= 10000 {
            if let firstMessage = truncatedMessages.first {
                totalCharCount -= firstMessage.content?.count ?? 0
                truncatedMessages.removeFirst()
            } else {
                break
            }
        }

        print("Total char count: \(totalCharCount)")

        await llm?.history = []
        for message in truncatedMessages {
            if message.role == .assistant {
                await llm?.history.append((.bot, message.content ?? ""))
            } else {
                var content = message.content ?? ""
                // If we have audio, we need to append the audio text to the message
                if let audio = message.audio {
                    content += audio.text
                }
                await llm?.history.append((.user, content))
            }
        }

        // Remove the last message as respond will generate a new one
        if let input = await llm?.history.popLast() {
            await llm?.respond(to: input.content, with: processOutputWrapped)
        }
    }

    @MainActor
    func achat(messages: [Message]) async -> Message {
        var truncatedMessages = messages

        // Add the audio text to the content of messages that have audio
        for (index, message) in truncatedMessages.enumerated() {
            if let audio = message.audio {
                truncatedMessages[index].content = (message.content ?? "") + audio.text
            }
        }

        var totalCharCount = truncatedMessages.reduce(0) { $0 + ($1.content?.count ?? 0) }

        while totalCharCount >= 5000 {
            if let firstMessage = truncatedMessages.first {
                totalCharCount -= firstMessage.content?.count ?? 0
                truncatedMessages.removeFirst()
            } else {
                break
            }
        }

        print("Total char count: \(totalCharCount)")

        await llm?.history = []
        for message in truncatedMessages {
            if message.role == .assistant {
                await llm?.history.append((.bot, message.content ?? ""))
            } else {
                var content = message.content ?? ""
                // If we have audio, we need to append the audio text to the message
                if let audio = message.audio {
                    content += audio.text
                }
                await llm?.history.append((.user, content))
            }
        }

        // Remove the last message as respond will generate a new one
        if let input = await llm?.history.popLast() {
            await llm?.respond(to: input.content)
        }

        let output = await llm?.output ?? ""

        return Message(content: output, role: .assistant)
    }

    func setup() async {
        let template = Template.mistral

        if downloadManager.verifyFile(
            at: modelInfo.localURL,
            expectedHash: modelInfo.hash
        ) {
            logger.debug("Verified \(self.modelInfo.name) at \(self.modelInfo.localURL)")

            logger.debug("Loading \(self.modelInfo.name) from \(self.modelInfo.localURL)")
            _llm = LLM(from: modelInfo.localURL)
            _llm?.template = template
        } else {
            logger.debug("Downloading \(self.modelInfo.name) from \(self.modelInfo.url)")
            do {
                try await downloadManager.download(
                    from: modelInfo.url,
                    to: modelInfo.localURL,
                    expectedHash: modelInfo.hash
                )

                logger.debug("Loading \(self.modelInfo.name) from \(self.modelInfo.localURL)")

                _llm = LLM(from: modelInfo.localURL)
                _llm?.template = template
            } catch {
                logger.error("Could not download \(self.modelInfo.name): \(error)")
            }
        }
    }

    func wipe() {
        try? FileManager.default.removeItem(at: modelInfo.localURL)
    }
}
