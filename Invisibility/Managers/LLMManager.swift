//
//  LLMManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/26/24.
//

import Combine
import Foundation
import OpenAI
import OSLog
import SwiftUI

struct LLMModel: Codable, Equatable, Hashable {
    let text: String
    let vision: String
    let human_name: String

    // Equatable
    static func == (lhs: LLMModel, rhs: LLMModel) -> Bool {
        lhs.text == rhs.text && lhs.vision == rhs.vision && lhs.human_name == rhs.human_name
    }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(vision)
        hasher.combine(human_name)
    }
}

enum LLMModels {
    static let claude3_opus = LLMModel(
        text: "anthropic/claude-3-opus:beta",
        vision: "anthropic/claude-3-opus:beta",
        human_name: "Claude-3 Opus"
    )

    static let gemini_pro = LLMModel(
        text: "google/gemini-pro",
        vision: "google/gemini-pro-vision",
        human_name: "Gemini Pro"
    )

    static let gpt4 = LLMModel(
        text: "gpt-4-turbo-preview",
        vision: "gpt-4-vision-preview",
        human_name: "GPT-4"
    )
}

@Observable
final class LLMManager: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "LLMManager")

    static let shared = LLMManager()

    private var ai: OpenAI

    private let timeoutInterval: TimeInterval = 20

    public var model: LLMModel = LLMModels.claude3_opus

    private init() {
        let configuration = OpenAI.Configuration(
            token: UserManager.shared.token ?? "",
            host: AppConfig.invisibility_api_base + "/oai",
            timeoutInterval: timeoutInterval
        )
        ai = OpenAI(configuration: configuration)
    }

    func setup() {
        let configuration = OpenAI.Configuration(
            token: UserManager.shared.token ?? "",
            host: AppConfig.invisibility_api_base + "/oai",
            timeoutInterval: timeoutInterval
        )
        ai = OpenAI(configuration: configuration)
    }

    func chat(
        messages: [Message],
        // Default processOutput function, just appends the output to a variable and returns it
        processOutput: @escaping (String) -> Void = { _ in }
    ) async {
        let chatQuery = await constructChatQuery(messages: messages.suffix(10).map { $0 })

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

    func constructChatQuery(messages: [Message]) async -> ChatQuery {
        var messages = messages

        // If the last message has any images use the vision model, otherwise use the regular model
        let allow_images = messages.last?.images?.count ?? 0 > 0

        let model_id: String = if allow_images {
            model.vision
        } else {
            model.text
        }

        // Ensure the first message is always from the user
        // First check if the 2nd message is from the user, if so pop the first message, otherwise insert a user message at the start
        if messages.first?.role != .user {
            if messages.count > 1, messages[1].role == .user {
                messages.removeFirst()
            } else {
                messages.insert(Message(content: "", role: .user), at: 0)
            }
        }

        let chat_messages = messages.compactMap { message in
            message.toChat(allow_images: allow_images)
        }

        // If the last message has any images use the vision model, otherwise use the regular model
        return ChatQuery(messages: chat_messages, model: model_id)
    }
}
