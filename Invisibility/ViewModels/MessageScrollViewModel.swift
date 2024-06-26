//
//  MessageScrollViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

final class MessageScrollViewModel: ObservableObject {
    static let shared = MessageScrollViewModel()

    /// A boolean value that indicates whether the text field should scroll to the bottom.
    @Published public var shouldScrollToBottom: Bool = false

    private init() {}

    @MainActor
    public func scrollToBottom() {
        shouldScrollToBottom = true
    }
}
