//
//  LLMManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Combine
import Foundation
import GPTEncoder
import OpenAI
import OSLog
import SwiftUI

final class LLMManager: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "LLMManager")

    static let shared = LLMManager()

    private let ai: OpenAI
    private let model: String = "mistralai/Mixtral-8x7B-Instruct-v0.1"
    private let encoder: GPTEncoder = GPTEncoder()

    private var cancellables: Set<AnyCancellable> = []

    static let maxTokenCountForMessage: Int = 16384
    static let maxTokenCount: Int = 32769
    static let maxNewTokens: Int = 2048

    private init() {
        let configuration = OpenAI.Configuration(token: "9dc11bc9c782a3d1743a63b6da951bf9ca8799d7232574d044de2d2afabc19a9", host: "api.together.xyz", timeoutInterval: 10)
        ai = OpenAI(configuration: configuration)
    }

    @MainActor
    func chat(
        messages: [Message],
        // Default processOutput function, just appends the output to a variable and returns it
        processOutput: @escaping (String) -> Void = { _ in }
    ) async {
        // For audio messages, chunk the input and summarize each chunk
        for message in messages {
            if message.audio != nil, message.summarizedChunks.count == 0, numTokens(message.text) > LLMManager.maxTokenCountForMessage {
                await message.generateSummarizedChunks()
            }
        }

        let messages = truncateMessages(messages: messages, maxTokenCount: LLMManager.maxTokenCount - LLMManager.maxNewTokens)
        let chatQuery = ChatQuery(messages: messages, model: model)

        do {
            for try await result in ai.chatsStream(query: chatQuery) {
                guard let content = result.choices.first?.delta.content else {
                    logger.error("No content in result")
                    return
                }
                processOutput(content)
            }
        } catch {
            logger.error("Error in chat: \(error)")
            AlertManager.shared.doShowAlert(title: "Chat Error", message: "Error in chat: \(error.localizedDescription)")
        }
    }

    // @MainActor
    func achat(messages: [Message]) async -> Message {
        let messages = truncateMessages(messages: messages, maxTokenCount: LLMManager.maxTokenCount - LLMManager.maxNewTokens)
        let chatQuery = ChatQuery(messages: messages, model: model)

        do {
            let result = try await ai.chats(query: chatQuery)
            return Message(content: result.choices.first?.message.content?.string ?? "")
        } catch {
            logger.error("Error in chat: \(error)")
            AlertManager.shared.doShowAlert(title: "Chat Error", message: "Error in chat: \(error.localizedDescription)")
            return Message(content: "Error in chat: \(error.localizedDescription)")
        }
    }

    func stop() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }

    /// Returns the number of tokens in the input text.
    public func numTokens(_ text: String) -> Int {
        let tokens = encoder.encode(text: text)
        return tokens.count
    }

    /// Splits the input string into chunks based on tokenization, aiming for each chunk to be close to `maxTokenCount`.
    /// - Parameters:
    ///   - input: The input string to be chunked.
    ///   - maxTokenCount: The maximum number of tokens allowed per chunk.
    /// - Returns: An array of string chunks, each chunk being close to the `maxTokenCount` limit.
    public func chunkInputByTokenCount(input: String, maxTokenCount: Int) -> [String] {
        let tokens = encoder.encode(text: input)

        // Group the tokens into chunks of maxTokenCount
        var chunks: [[Int]] = []
        var currentChunk: [Int] = []
        var currentTokenCount = 0

        for token in tokens {
            if currentTokenCount + 1 <= maxTokenCount {
                currentChunk.append(token)
                currentTokenCount += 1 // Or += token.count if tokens have variable lengths
            } else {
                chunks.append(currentChunk)
                currentChunk = [token]
                currentTokenCount = 1 // Or = token.count
            }
        }

        // Don't forget to add the last chunk if it's not empty
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        // Token counts print
        let tokenCounts = chunks.map { chunk in chunk.count }
        logger.debug("Token counts: \(tokenCounts)")

        let chunks_decoded = chunks.map { encoder.decode(tokens: $0) }

        return chunks_decoded
    }

    /// Returns list of tokens, encoded from the history, truncated to the maximum token count.
    private func truncateMessages(messages: [Message], maxTokenCount: Int) -> [ChatQuery.ChatCompletionMessageParam] {
        var truncatedChats: [ChatQuery.ChatCompletionMessageParam] = []
        var token_count: Int { numTokens(truncatedChats.map { message in message.content?.string ?? "" }.joined(separator: "\n\n")) }

        /// Buffer to add (remove, really) to the max token count to enforce more truncation
        // let buffer = Double(maxTokenCount) * 0.10

        // In reverse, prepend content to each chat until we reach the max token count
        for message in messages.reversed() {
            guard let chat = message.toChat() else {
                logger.error("Chat is nil")
                continue
            }

            if numTokens(chat.content?.string ?? "") + token_count > maxTokenCount {
                logger.debug("Break at token count: \(token_count)")
                break
            }

            truncatedChats.insert(chat, at: 0)
        }

        return truncatedChats
    }
}
