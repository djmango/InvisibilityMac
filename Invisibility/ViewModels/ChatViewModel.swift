//
//  ChatViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog
import PostHog
import SwiftUI

final class ChatViewModel: ObservableObject {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "ChatViewModel")

    static let shared = ChatViewModel()

    @AppStorage("token") private var token: String?

    /// The currently viewed chat.
    @Published public private(set) var chat: APIChat? {
        didSet {
            print("ChatViewModel: chat set to \(chat?.name ?? "nil")")
        }
    }

    private init() {}

    @MainActor
    func newChat() -> APIChat? {
        defer { PostHogSDK.shared.capture("new_chat") }
        guard let user = UserManager.shared.user else {
            logger.error("User not found")
            return nil
        }

        chat = APIChat(
            id: UUID(),
            user_id: user.id
        )
        withAnimation(AppConfig.snappy) {
            _ = MainWindowViewModel.shared.changeView(to: .chat)
            if let chat {
                MessageViewModel.shared.api_chats.append(chat)
            }
        }
        return chat
    }

    @MainActor
    func switchChat(_ chat: APIChat?) {
        defer { PostHogSDK.shared.capture("switch_chat") }

        // Attempt to switch to the chat, or create a new one if none is provided
        guard let chat else {
            if let newChat = newChat() {
                self.chat = newChat
            }
            return
        }

        withAnimation(AppConfig.snappy) {
            self.chat = chat
        }
    }

    @MainActor
    func deleteChat(_ chat: APIChat) {
        defer { PostHogSDK.shared.capture("delete_chat") }
        withAnimation {
            MessageViewModel.shared.api_chats.removeAll { $0 == chat }
        }
        if self.chat == chat {
            switchChat(MessageViewModel.shared.api_chats.first)
        }

        // DELETE chat
        Task {
            guard let url = URL(string: AppConfig.invisibility_api_base + "/chats/\(chat.id)") else {
                return
            }
            guard let token else {
                logger.warning("No token for delete")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)

            logger.debug(String(data: data, encoding: .utf8) ?? "No data")
        }
    }

    @MainActor
    func renameChat(_ chat: APIChat, name: String) {
        defer { PostHogSDK.shared.capture("rename_chat", properties: ["name": name]) }

        guard let index = MessageViewModel.shared.api_chats.firstIndex(of: chat) else {
            logger.error("Chat not found")
            return
        }
        MessageViewModel.shared.api_chats[index].name = name

        // PUT chat
        Task {
            guard let url = URL(string: AppConfig.invisibility_api_base + "/chats/\(chat.id)") else {
                return
            }
            guard let token else {
                logger.warning("No token for patch")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let encoder = JSONEncoder()
            let payload = RenameRequest(name: name)

            // Try encoding the payload to JSON data, handling any encoding errors
            do {
                let data = try encoder.encode(payload)
                request.httpBody = data
            } catch {
                logger.error("Failed to encode payload: \(error)")
                return
            }

            let (responseData, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            let responseString = String(data: responseData, encoding: .utf8) ?? "No data"
            logger.debug("Response Data: \(responseString)")
        }
    }
    
    @MainActor
    func autoRename(_ chat: APIChat, body: String? = nil) async -> String {
        var resultName = ""
        let limit = 4000
        let firstMessagePrefix = String((MessageViewModel.shared.firstMessageWithTextFor(chat: chat)?.text.prefix(limit)) ?? "")
        let lastMessagePrefix = String(body?.suffix(limit) ?? "")
        let bodyText = firstMessagePrefix + lastMessagePrefix
        
        guard let url = URL(string: AppConfig.invisibility_api_base + "/chats/\(chat.id)/autorename") else {
            return resultName
        }
        guard let token else {
            logger.warning("No token for patch")
            return resultName
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        let payload = AutoRenameRequest(text: bodyText)

        // Try encoding the payload to JSON data, handling any encoding errors
        do {
            let data = try encoder.encode(payload)
            request.httpBody = data
        } catch {
            logger.error("Failed to encode payload: \(error)")
            return resultName
        }

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("HTTP Response Status Code: \(httpResponse.statusCode)")
            }
            
            let decoder = iso8601Decoder()
            let resultChat = try decoder.decode(APIChat.self, from: responseData)
            resultName = resultChat.name
            logger.debug("Response Data: \(resultName)")
            
        } catch {
            logger.error("Request failed: \(error)")
        }

        return resultName
    }
}
