//
//  MessageScrollViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Combine
import Foundation

final class MessageScrollViewModel: ObservableObject {
    static let shared = MessageScrollViewModel()

    /// A boolean value that indicates whether the text field should scroll to the bottom.
    @Published private(set) var canSendMessages: Bool = true
    @Published private(set) var chat: APIChat?
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var isRecording: Bool = false
    @Published public var shouldScrollToBottom: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    private let chatViewModel: ChatViewModel = ChatViewModel.shared
    private let messageViewModel: MessageViewModel = MessageViewModel.shared
    private let screenRecorder: ScreenRecorder = ScreenRecorder.shared
    private let userManager: UserManager = UserManager.shared

    var api_messages_in_chat: [APIMessage] {
        messageViewModel.api_messages_in_chat
    }

    private init() {
        Task { @MainActor in
            screenRecorder.$isRunning
                .receive(on: DispatchQueue.main)
                .assign(to: \.isRecording, on: self)
                .store(in: &cancellables)
        }

        messageViewModel.$isGenerating
            .receive(on: DispatchQueue.main)
            .assign(to: \.isGenerating, on: self)
            .store(in: &cancellables)

        chatViewModel.$chat
            .receive(on: DispatchQueue.main)
            .assign(to: \.chat, on: self)
            .store(in: &cancellables)

        // Subscribe to changes in canSendMessages from UserManager
         userManager.$canSendMessages
             .receive(on: DispatchQueue.main)
             .assign(to: \.canSendMessages, on: self)
             .store(in: &cancellables)
    }

    @MainActor
    public func scrollToBottom() {
        shouldScrollToBottom = true
    }
}
