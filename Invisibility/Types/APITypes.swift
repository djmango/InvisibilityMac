//
//  APITypes.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Combine
import Foundation
import OpenAI
import SwiftUI

struct APIChat: Codable, Identifiable, Hashable {
    let id: UUID
    let user_id: String
    var name: String
    let created_at: Date
    let updated_at: Date

    init(
        id: UUID,
        user_id: String,
        name: String = "New Chat",
        created_at: Date = Date(),
        updated_at: Date = Date()
    ) {
        self.id = id
        self.user_id = user_id
        self.name = name
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

enum APIRole: String, Codable {
    case assistant
    case system
    case tool
    case user

    // Conform to the CustomStringConvertible protocol for debugging output
    var description: String {
        self.rawValue
    }
}

class APIMessage: ObservableObject, Codable, Identifiable {
    let id: UUID
    let chat_id: UUID
    let user_id: String
    @Published var text: String
    let role: APIRole
    var regenerated: Bool
    let created_at: Date
    let updated_at: Date

    enum CodingKeys: CodingKey {
        case id, chat_id, user_id, text, role, regenerated, created_at, updated_at
    }

    /// Conforms to `CustomStringConvertible` for debugging output.
    var description: String {
        "\(role): \(text)"
    }

    // Initializer for convenience
    init(
        id: UUID,
        chat_id: UUID,
        user_id: String,
        text: String,
        role: APIRole,
        regenerated: Bool = false,
        created_at: Date = Date(),
        updated_at: Date = Date()
    ) {
        self.id = id
        self.chat_id = chat_id
        self.user_id = user_id
        self.text = text
        self.role = role
        self.regenerated = regenerated
        self.created_at = created_at
        self.updated_at = updated_at
    }

    // Codable conformance using synthesized init/encode
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.chat_id = try container.decode(UUID.self, forKey: .chat_id)
        self.user_id = try container.decode(String.self, forKey: .user_id)
        self.text = try container.decode(String.self, forKey: .text)
        self.role = try container.decode(APIRole.self, forKey: .role)
        self.regenerated = try container.decode(Bool.self, forKey: .regenerated)
        self.created_at = try container.decode(Date.self, forKey: .created_at)
        self.updated_at = try container.decode(Date.self, forKey: .updated_at)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(chat_id, forKey: .chat_id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(text, forKey: .text)
        try container.encode(role, forKey: .role)
        try container.encode(regenerated, forKey: .regenerated)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(updated_at, forKey: .updated_at)
    }
}

/// Filetype representation, ensures lowercase coding keys
enum APIFiletype: String, Codable, Equatable, CustomStringConvertible {
    case jpeg
    case pdf
    case mp4
    case mp3

    /// Conforms to `CustomStringConvertible` for debugging output.
    var description: String {
        self.rawValue
    }
}

/// File representation with necessary properties and codable conformance
struct APIFile: Codable, Equatable {
    let id: UUID
    let message_id: UUID
    let chat_id: UUID
    let user_id: String
    let filetype: APIFiletype
    let show_to_user: Bool
    let url: String?
    let created_at: Date
    let updated_at: Date

    init(
        id: UUID,
        message_id: UUID,
        chat_id: UUID,
        user_id: String,
        filetype: APIFiletype,
        show_to_user: Bool,
        url: String?,
        created_at: Date = Date(),
        updated_at: Date = Date()
    ) {
        self.id = id
        self.message_id = message_id
        self.chat_id = chat_id
        self.user_id = user_id
        self.filetype = filetype
        self.show_to_user = show_to_user
        self.url = url
        self.created_at = created_at
        self.updated_at = updated_at
    }

    func copyToMessage(message: APIMessage) -> APIFile {
        APIFile(
            id: id,
            message_id: message.id,
            chat_id: chat_id,
            user_id: user_id,
            filetype: filetype,
            show_to_user: show_to_user,
            url: url,
            created_at: created_at,
            updated_at: updated_at
        )
    }
}

// Define a struct for the response
struct APIChatsAndMessagesResponse: Codable {
    let chats: [APIChat]
    let messages: [APIMessage]
    let files: [APIFile]
}
