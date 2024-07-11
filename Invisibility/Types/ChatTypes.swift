//
//  ChatTypes.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

struct RenameRequest: Codable {
    let name: String
}

struct AutoRenameRequest: Codable {
    let text: String
}

struct ChatDataItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let data: Data
    let dataType: APIFiletype
    let hide: Bool

    init(data: Data, dataType: APIFiletype, hide: Bool = false) {
        self.data = data
        self.dataType = dataType
        self.hide = hide
    }

    static func == (lhs: ChatDataItem, rhs: ChatDataItem) -> Bool {
        lhs.id == rhs.id
    }

    func toAPI(message: APIMessage) -> APIFile {
        APIFile(
            id: UUID(),
            message_id: message.id,
            chat_id: message.chat_id,
            user_id: message.user_id,
            filetype: dataType,
            show_to_user: !hide,
            // Data to base64. Needs the correct prefix for the data type.
            url: "data:image/jpeg;base64,\(data.base64EncodedString())"
        )
    }
}
