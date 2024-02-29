//
//  ChatViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog

struct ChatImageItem: Identifiable {
    let id = UUID()
    let imageData: Data
}

@Observable
final class ChatViewModel: ObservableObject {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "ChatViewModel")

    static let shared = ChatViewModel()

    /// List of JPEG images to be sent with the message
    public var images: [ChatImageItem] = []

    /// UUID of the currently hovered image
    public var whoIsHovering: UUID?

    private init() {}

    @MainActor
    public func addImage(_ data: Data) {
        images.append(ChatImageItem(imageData: data))
    }

    @MainActor
    public func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }
}
