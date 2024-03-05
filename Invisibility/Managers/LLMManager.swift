//
//  LLMManager.swift
//  Invisibility
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
    private let logger = Logger(subsystem: "so.invisibility.app", category: "LLMManager")

    static let shared = LLMManager()

    private var ai: OpenAI
    // private let host: String = "http://localhost:8000/oai"
    private let host: String = "cloak.invisibility.so/oai"
    private let encoder: GPTEncoder = GPTEncoder()

    static let maxInputTokenCount: Int = 8192
    static let maxInputTokenCountVision: Int = 2048
    static let maxTokenCountPerMessage: Int = 4096
    static let maxNewTokens: Int = 2048

    private init() {
        let token = UserManager.shared.token ?? ""
        let configuration = OpenAI.Configuration(
            token: token,
            host: host,
            timeoutInterval: 10
        )
        ai = OpenAI(configuration: configuration)
    }

    func setup() {
        let token = UserManager.shared.token ?? ""
        let configuration = OpenAI.Configuration(
            token: token,
            host: host,
            timeoutInterval: 10
        )
        ai = OpenAI(configuration: configuration)
    }

    func chat(
        messages: [Message],
        // Default processOutput function, just appends the output to a variable and returns it
        processOutput: @escaping (String) -> Void = { _ in }
    ) async {
        let chatQuery = await constructChatQuery(messages: messages)

        do {
            for try await result in ai.chatsStream(query: chatQuery) {
                let content = result.choices.first?.delta.content ?? ""
                if content.isEmpty {
                    logger.warning("No content in result")
                }
                processOutput(content)
            }
        } catch {
            logger.error("Error in chat: \(error)")
            AlertManager.shared.doShowAlert(title: "Chat Error", message: "Error in chat: \(error.localizedDescription)")
        }
    }

    func achat(messages: [Message]) async -> Message {
        let chatQuery = await constructChatQuery(messages: messages)

        do {
            let result = try await ai.chats(query: chatQuery)
            return Message(content: result.choices.first?.message.content?.string ?? "")
        } catch {
            logger.error("Error in chat: \(error)")
            AlertManager.shared.doShowAlert(title: "Chat Error", message: "Error in chat: \(error.localizedDescription)")
            return Message(content: "Error in chat: \(error.localizedDescription)")
        }
    }

    func constructChatQuery(messages: [Message]) async -> ChatQuery {
        let vision_model: String = "gpt-4-vision-preview"
        let reg_model: String = "gpt-4-turbo-preview"

        // If the last message has any images use the vision model, otherwise use the regular model
        let model: String = if messages.last?.images?.count ?? 0 > 0 {
            vision_model
        } else {
            reg_model
        }

        // For audio messages, chunk the input and summarize each chunk
        for message in messages {
            if message.audio != nil, message.summarizedChunks.count == 0,
               numTokens(message.text) > LLMManager.maxTokenCountPerMessage
            {
                await message.generateSummarizedChunks()
            }
        }

        let maxTokens = if model == vision_model {
            LLMManager.maxInputTokenCountVision
        } else {
            LLMManager.maxInputTokenCount
        }

        let chat_messages = truncateMessages(
            messages: messages,
            maxTokenCount: maxTokens,
            allow_images: model == vision_model
        )

        // If the last message has any images use the vision model, otherwise use the regular model
        return ChatQuery(messages: chat_messages, model: model, maxTokens: LLMManager.maxNewTokens)
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
    private func truncateMessages(messages: [Message], maxTokenCount: Int, allow_images: Bool) -> [ChatQuery.ChatCompletionMessageParam] {
        var truncatedChats: [ChatQuery.ChatCompletionMessageParam] = []
        var token_count: Int { numTokens(truncatedChats.map { message in message.content?.string ?? "" }.joined(separator: "\n\n")) }

        /// Buffer to add (remove, really) to the max token count to enforce more truncation
        // let buffer = Double(maxTokenCount) * 0.10

        // In reverse, prepend content to each chat until we reach the max token count
        for message in messages.reversed() {
            guard let chat = message.toChat(allow_images: allow_images) else {
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
