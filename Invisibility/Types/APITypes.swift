//
//  APITypes.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

struct APIChat: Codable, Identifiable {
    let id: UUID
    let user_id: String
    let name: String
    let created_at: Date
    let updated_at: Date
}

struct APIMessage: Codable {
    var id: UUID
    let chat_id: UUID
    let user_id: String
    let text: String
    let role: String
    let regenerated: Bool
    let created_at: Date
    let updated_at: Date
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
    let chat_id: UUID
    let user_id: String
    let message_id: UUID
    let filetype: APIFiletype
    let show_to_user: Bool
    let url: String?
    let created_at: Date
    let updated_at: Date
}

// Define a struct for the response
struct APIChatsAndMessagesResponse: Codable {
    let chats: [APIChat]
    let messages: [APIMessage]
    let files: [APIFile]
}
