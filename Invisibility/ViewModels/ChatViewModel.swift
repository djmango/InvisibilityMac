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

final class ChatViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatViewModel")

    static let shared = ChatViewModel()

    /// A boolean value that indicates whether the text field should be focused.
    @Published public var shouldFocusTextField: Bool = false

    /// List of JPEG images to be sent with the message
    @Published public var images: [ChatImageItem] = []

    /// The height of the text field.
    @Published public var textHeight: CGFloat = 52

    private init() {}

    @MainActor
    public func addImage(_ data: Data) {
        images.append(ChatImageItem(imageData: data))
    }

    @MainActor
    public func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    @MainActor
    public func focusTextField() {
        shouldFocusTextField = true
    }
}
