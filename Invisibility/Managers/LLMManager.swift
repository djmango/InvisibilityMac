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
import PostHog
import SwiftUI

struct LLMModel: Codable, Equatable, Hashable {
    let text: String
    let vision: String?
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

    static let claude3_sonnet = LLMModel(
        text: "anthropic/claude-3-sonnet:beta",
        vision: "anthropic/claude-3-sonnet:beta",
        human_name: "Claude-3 Sonnet"
    )

    static let claude3_haiku = LLMModel(
        text: "anthropic/claude-3-haiku:beta",
        vision: "anthropic/claude-3-haiku:beta",
        human_name: "Claude-3 Haiku"
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

    static let gpt3 = LLMModel(
        text: "gpt-3.5-turbo",
        vision: nil,
        human_name: "GPT-3.5"
    )

    static let groq_mixtral = LLMModel(
        text: "groq/mixtral-8x7b-32768",
        vision: nil,
        human_name: "Groq-Mixtral"
    )

    static let perplexity_sonar_online = LLMModel(
        text: "perplexity/sonar-medium-online",
        vision: nil,
        human_name: "Perplexity"
    )

    static let perplexity_mixtral = LLMModel(
        text: "perplexity/mixtral-8x7b-instruct",
        vision: nil,
        human_name: "Mixtral"
    )

    static let human_name_to_model: [String: LLMModel] = [
        claude3_opus.human_name: claude3_opus,
        claude3_sonnet.human_name: claude3_sonnet,
        claude3_haiku.human_name: claude3_haiku,
        gemini_pro.human_name: gemini_pro,
        gpt4.human_name: gpt4,
        groq_mixtral.human_name: groq_mixtral,
        perplexity_sonar_online.human_name: perplexity_sonar_online,
        perplexity_mixtral.human_name: perplexity_mixtral,
    ]
}

final class LLMManager {
    static let shared = LLMManager()

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "LLMManager")

    private var ai: OpenAI

    private let timeoutInterval: TimeInterval = 30

    private var model: LLMModel {
        LLMModels.human_name_to_model[llmModel] ?? LLMModels.claude3_opus
    }

    @AppStorage("llmModel") private var llmModel = LLMModels.claude3_opus.human_name

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
            PostHogSDK.shared.capture("chat_error", properties: ["error": error.localizedDescription, "model": model.human_name])
            AlertManager.shared.doShowAlert(title: "Chat Error", message: "\(error.localizedDescription)")
        }
    }

    func constructChatQuery(messages: [Message]) async -> ChatQuery {
        var messages = messages

        // If the last message has any images use the vision model, otherwise use the regular model
        let allow_images = messages.last?.images.count ?? 0 > 0 && model.vision != nil

        let model_id: String = if allow_images {
            model.vision ?? model.text
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
