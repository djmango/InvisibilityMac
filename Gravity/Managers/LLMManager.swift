//
//  LLMManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Combine
import Foundation
import OpenAI
import OSLog
import SwiftUI

final class LLMManager: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "LLMManager")

    static let shared = LLMManager()

    private let ai: OpenAI
    private let model: String = "mistralai/Mixtral-8x7B-Instruct-v0.1"

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        let configuration = OpenAI.Configuration(token: "9dc11bc9c782a3d1743a63b6da951bf9ca8799d7232574d044de2d2afabc19a9", host: "api.together.xyz", timeoutInterval: 10)
        ai = OpenAI(configuration: configuration)
    }

    @MainActor
    func chat(
        messages: [Message],
        // Default processOutput function, just appends the output to a variable and returns it
        processOutput: @escaping (String) -> Void = { _ in }
    ) async throws {
        // For audio messages, chunk the input and summarize each chunk
        // for message in messages {
        //     if message.audio != nil, message.summarizedChunks.count == 0, await llm?.numTokens(message.text) ?? 0 > 1024 {
        //         await message.generateSummarizedChunks()
        //     }
        // }

        let messages = messages.compactMap { message in message.toChat() }
        let chatQuery = ChatQuery(messages: messages, model: model)

        do {
            for try await result in ai.chatsStream(query: chatQuery) {
                guard let content = result.choices.first?.delta.content else {
                    logger.error("No content in result")
                    return
                }
                logger.debug("Chat response: \(content)")
                processOutput(content)
            }
        } catch {
            logger.error("Error in chat: \(error)")
            throw error
        }
    }

    // @MainActor
    func achat(messages: [Message]) async -> Message {
        let messages = messages.compactMap { message in message.toChat() }
        let chatQuery = ChatQuery(messages: messages, model: model)

        let result = try? await ai.chats(query: chatQuery)
        return Message(content: result?.choices.first?.message.content?.string ?? "")
    }

    func stop() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
}
