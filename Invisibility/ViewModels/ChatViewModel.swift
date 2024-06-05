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

struct ChatDataItem: Identifiable, Equatable {
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

final class ChatViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatViewModel")

    static let shared = ChatViewModel()

    /// The currently viewed chat.
    @Published public var chat: APIChat?

    /// A boolean value that indicates whether the text field should be focused.
    @Published public var shouldFocusTextField: Bool = false

    /// A boolean value that indicates whether the text field should scroll to the bottom.
    @Published public var shouldScrollToBottom: Bool = false

    /// List of JPEG images and items to be sent with the message
    @Published public var items: [ChatDataItem] = []

    public var images: [ChatDataItem] {
        items.filter { $0.dataType == .jpeg }
    }

    public var pdfs: [ChatDataItem] {
        items.filter { $0.dataType == .pdf }
    }

    /// The height of the text field.
    @Published public var textHeight: CGFloat = 52
    @Published public var lastTextHeight: CGFloat = 0

    private init() {}

    @MainActor
    public func addImage(_ data: Data, hide: Bool = false) {
        items.append(ChatDataItem(data: data, dataType: .jpeg, hide: hide))
    }

    @MainActor
    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }

    @MainActor
    public func removeAll() {
        items.removeAll()
    }

    @MainActor
    public func focusTextField() {
        shouldFocusTextField = true
    }

    @MainActor
    func newChat() {
        defer { PostHogSDK.shared.capture("new_chat") }
        guard let user = UserManager.shared.user else {
            logger.error("User not found")
            return
        }

        ChatViewModel.shared.chat = APIChat(
            id: UUID(),
            user_id: user.id
        )

        MessageViewModel.shared.api_chats.append(chat!)
    }

    @MainActor
    func switchChat(_ chat: APIChat) {
        defer { PostHogSDK.shared.capture("switch_chat") }
        ChatViewModel.shared.chat = chat
    }
}
