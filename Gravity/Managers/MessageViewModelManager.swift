//
//  MessageViewModelManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation

final class MessageViewModelManager {
    static let shared = MessageViewModelManager()

    let messageViewModel: MessageViewModel

    private init() {
        messageViewModel = MessageViewModel()
    }
}
