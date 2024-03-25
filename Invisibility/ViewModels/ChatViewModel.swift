//
//  ChatViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog

struct ChatImageItem: Identifiable, Equatable {
    let id = UUID()
    let imageData: Data

    static func == (lhs: ChatImageItem, rhs: ChatImageItem) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
final class ChatViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatViewModel")

    static let shared = ChatViewModel()

    /// A boolean value that indicates whether the text field should be focused.
    public var shouldFocusTextField: Bool = false

    /// List of JPEG images to be sent with the message
    public var images: [ChatImageItem] = []

    /// UUID of the currently hovered image
    public var whoIsHovering: UUID?

    /// The height of the text field.
    public var textHeight: CGFloat = 52

    // The text content of the chat field
    public var text: String = ""

    private init() {}

    public func addImage(_ data: Data) {
        images.append(ChatImageItem(imageData: data))
    }

    public func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    public func focusTextField() {
        shouldFocusTextField = true
    }
}
