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

enum LLMModels: CaseIterable {
    case claude3Opus
    case claude3Sonnet
    case claude3Haiku
    case geminiPro
    case gpt4
    case groqMixtral
    case perplexitySonarOnline
    case perplexityMixtral
    case dbrxTogether

    var model: LLMModel {
        switch self {
        case .claude3Opus:
            LLMModel(
                text: "claude-3-opus-20240229",
                vision: "claude-3-opus-20240229",
                human_name: "Claude-3 Opus"
            )
        case .claude3Sonnet:
            LLMModel(
                text: "claude-3-sonnet-20240229",
                vision: "claude-3-sonnet-20240229",
                human_name: "Claude-3 Sonnet"
            )
        case .claude3Haiku:
            LLMModel(
                text: "claude-3-haiku-20240307",
                vision: "claude-3-haiku-20240307",
                human_name: "Claude-3 Haiku"
            )
        case .geminiPro:
            LLMModel(
                text: "openrouter/google/gemini-pro-1.5",
                vision: "openrouter/google/gemini-pro-1.5",
                human_name: "Gemini Pro 1.5"
            )
        case .gpt4:
            LLMModel(
                text: "gpt-4-turbo-2024-04-09",
                vision: "gpt-4-turbo-2024-04-09",
                human_name: "GPT-4 Turbo"
            )
        case .groqMixtral:
            LLMModel(
                text: "groq/mixtral-8x7b-32768",
                vision: nil,
                human_name: "Groq-Mixtral"
            )
        case .perplexitySonarOnline:
            LLMModel(
                text: "perplexity/sonar-medium-online",
                vision: nil,
                human_name: "Perplexity"
            )
        case .perplexityMixtral:
            LLMModel(
                text: "perplexity/mixtral-8x7b-instruct",
                vision: nil,
                human_name: "Mixtral"
            )
        case .dbrxTogether:
            LLMModel(
                text: "openrouter/databricks/dbrx-instruct",
                vision: nil,
                human_name: "DBRX (Uncensored)"
            )
        }
    }

    static var allModels: [LLMModel] {
        allCases.map(\.model)
    }

    static var humanNameToModel: [String: LLMModel] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0.model.human_name, $0.model) })
    }
}

final class LLMManager {
    static let shared = LLMManager()

    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "LLMManager")

    private var ai: OpenAI

    private let timeoutInterval: TimeInterval = 30

    @AppStorage("token") private var token: String?

    public var model: LLMModel {
        LLMModels.humanNameToModel[llmModel] ?? LLMModels.claude3Opus.model
    }

    public var modelIndex: Int {
        LLMModels.allModels.firstIndex(of: model) ?? 0
    }

    public func setModel(index: Int) {
        llmModel = LLMModels.allModels[index].human_name
    }

    @AppStorage("llmModelName") private var llmModel = LLMModels.claude3Opus.model.human_name

    private init() {
        @AppStorage("token") var token: String?
        let configuration = OpenAI.Configuration(
            token: token ?? "",
            host: AppConfig.invisibility_api_base + "/oai",
            timeoutInterval: timeoutInterval
        )
        ai = OpenAI(configuration: configuration)
    }

    func setup() {
        let configuration = OpenAI.Configuration(
            token: token ?? "",
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
        let allow_images = messages.last?.images_data.count ?? 0 > 0 && model.vision != nil

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
