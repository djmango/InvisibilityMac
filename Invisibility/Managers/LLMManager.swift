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

// Alias for ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent(images: images)
typealias VisionContent = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent

struct LLMModel: Codable, Equatable, Hashable, Identifiable {
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

    // Identifiable
    var id: String {
        human_name
    }
}

enum LLMModelRepository: CaseIterable {
    case gpt4o
    case claude3Opus
    case llama3_70b
    case geminiPro
    case perplexitySonarOnline

    var model: LLMModel {
        switch self {
        case .gpt4o:
            LLMModel(
                text: "gpt-4o",
                vision: "gpt-4o",
                human_name: "GPT-4o"
            )
        case .claude3Opus:
            LLMModel(
                text: "bedrock/anthropic.claude-3-opus-20240229-v1:0",
                vision: "bedrock/anthropic.claude-3-opus-20240229-v1:0",
                human_name: "Claude-3 Opus"
            )
        case .llama3_70b:
            LLMModel(
                text: "groq/llama3-70b-8192",
                vision: nil,
                human_name: "Llama-3 70B"
            )
        case .geminiPro:
            LLMModel(
                text: "openrouter/google/gemini-pro-1.5",
                vision: "openrouter/google/gemini-pro-1.5",
                human_name: "Gemini Pro 1.5"
            )
        case .perplexitySonarOnline:
            LLMModel(
                text: "openrouter/perplexity/llama-3-sonar-large-32k-online",
                vision: nil,
                human_name: "Perplexity"
            )
        }
    }

    static var allModels: [LLMModel] {
        allCases.map(\.model)
    }

    static var enabledModels: [LLMModel] {
        var enabledModels: [LLMModel] = []
        for model in allCases {
            if UserDefaults.standard.bool(forKey: "llmEnabled_\(model.model.human_name)") {
                enabledModels.append(model.model)
            }
        }
        return enabledModels
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
        LLMModelRepository.humanNameToModel[llmModel] ?? LLMModelRepository.gpt4o.model
    }

    /// The index of the model in the allModels array
    public var modelIndex: Int {
        LLMModelRepository.allModels.firstIndex(of: model) ?? 0
    }

    /// The index of the model in the enabledModels array
    public var enabledModelIndex: Int {
        LLMModelRepository.enabledModels.firstIndex(of: model) ?? 0
    }

    /// All enabled models via UserDefaults
    public var enabledModels: [LLMModel] {
        var enabledModels: [LLMModel] = []
        for model in LLMModelRepository.allModels {
            if UserDefaults.standard.bool(forKey: "llmEnabled_\(model.human_name)") {
                enabledModels.append(model)
            }
        }
        return enabledModels
    }

    /// Set the model to the given index in the enabled models
    public func setModel(index: Int) {
        llmModel = LLMModelRepository.enabledModels[index].human_name
    }

    @AppStorage("llmModelName") private var llmModel = LLMModelRepository.gpt4o.model.human_name

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
        messages: [APIMessage],
        chat: APIChat,
        processOutput: @escaping (String, APIMessage) -> Void,
        regenerate_from_message_id: UUID? = nil
    ) async {
        guard let assistantMessage = messages.last else {
            logger.error("No messages in chat query")
            return
        }

        // Drop last to avoid sending the empty assistant message to the LLM
        let chatQuery = await constructChatQuery(
            messages: messages.dropLast().suffix(10).map { $0 },
            chat: chat,
            regenerate_from_message_id: regenerate_from_message_id
        )

        do {
            var receivedData: Bool = false
            for try await result in ai.chatsStream(query: chatQuery) {
                if !receivedData { receivedData = true }
                let content = result.choices.first?.delta.content ?? ""
                if content.isEmpty {
                    logger.warning("No content in result")
                }
                processOutput(content, assistantMessage)
            }
            if !receivedData {
                logger.error("No data received from chat")
                PostHogSDK.shared.capture("chat_error", properties: ["error": "No data received from chat", "model": model.human_name])
                ToastViewModel.shared.showToast(title: "No data received from model. Please try again.")
                DispatchQueue.main.async {
                    MessageViewModel.shared.isGenerating = false
                }
            }
        } catch {
            logger.error("Error in chat: \(error)")
            PostHogSDK.shared.capture("chat_error", properties: ["error": error.localizedDescription, "model": model.human_name])
            ToastViewModel.shared.showToast(title: "Chat Error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                MessageViewModel.shared.isGenerating = false
            }
        }
    }

    func constructChatQuery(messages: [APIMessage], chat: APIChat, regenerate_from_message_id: UUID? = nil) async -> ChatQuery {
        // If the last message has any images use the vision model, otherwise use the regular model
        let allow_images = model.vision != nil

        let model_id: String = if allow_images {
            model.vision ?? model.text
        } else {
            model.text
        }

        var chat_messages = messages.compactMap { message in
            oaiFromAPIMessage(api_message: message, allow_images: allow_images)
        }

        // Ensure the first message is always from the user
        // First check if the 2nd message is from the user, if so pop the first message, otherwise insert a user message at the start
        if chat_messages.first?.role != .user {
            if chat_messages.count > 1, chat_messages[1].role == .user {
                chat_messages.removeFirst()
            } else {
                if let chat_query = ChatQuery.ChatCompletionMessageParam(role: .user, content: "") {
                    chat_messages.insert(chat_query, at: 0)
                } else {
                    logger.error("Failed to create user message")
                }
            }
        }

        var chat_query = ChatQuery(messages: chat_messages, model: model_id)

        if let last_message = messages.last {
            let show_files_to_user: [Bool] = MessageViewModel.shared.imagesFor(message: last_message).map(\.show_to_user)

            chat_query.invisibility = ChatQuery.InvisibilityMetadata(
                chat_id: chat.id,
                user_message_id: last_message.id,
                show_files_to_user: show_files_to_user,
                regenerate_from_message_id: regenerate_from_message_id
            )
        }

        return chat_query
    }
}

func oaiFromAPIMessage(api_message: APIMessage, allow_images: Bool = false) -> ChatQuery.ChatCompletionMessageParam? {
    var role: ChatQuery.ChatCompletionMessageParam.Role = .user
    if api_message.role == .assistant {
        role = .assistant
    } else if api_message.role == .system {
        role = .system
    }

    let complete_text: String = api_message.text
    let api_files: [APIFile] = MessageViewModel.shared.imagesFor(message: api_message)

    if allow_images, !api_files.isEmpty {
        // Images, multimodal
        let imageUrls = api_files.compactMap { file -> VisionContent.ChatCompletionContentPartImageParam.ImageURL? in
            guard let url = file.url else { return nil }
            return VisionContent.ChatCompletionContentPartImageParam.ImageURL(url: url, detail: .auto)
        }
        let imageParams = imageUrls.map { VisionContent.ChatCompletionContentPartImageParam(imageUrl: $0) }
        let visionContent = imageParams.map { VisionContent(chatCompletionContentPartImageParam: $0) }

        let textParam = VisionContent.ChatCompletionContentPartTextParam(text: complete_text)
        let textVisionContent = [VisionContent(chatCompletionContentPartTextParam: textParam)]

        let content = textVisionContent + visionContent

        return ChatQuery.ChatCompletionMessageParam(role: role, content: content)
    } else {
        // Pure text
        return ChatQuery.ChatCompletionMessageParam(role: role, content: complete_text)
    }
}
