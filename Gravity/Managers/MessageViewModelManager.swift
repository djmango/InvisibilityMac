//
//  MessageViewModelManager.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 12/23/23.
//

import Foundation
import SwiftData

/// MessageViewModelManager is a singleton class responsible for managing instances of MessageViewModel.
/// It ensures that only one instance of MessageViewModel is created and used per chat.
/// It is initiated only one time in GravityApp.init
class MessageViewModelManager {
    /// The shared static instance allows global access to the MessageViewModelManager.
    static var shared = MessageViewModelManager()
    /// A dictionary to store and reuse MessageViewModel instances, keyed by chatID.
    private var viewModels: [Chat: MessageViewModel] = [:]

    // Function to retrieve a MessageViewModel for a given chatID.
    // It reuses existing view models or creates a new one if not already present.
    func viewModel(for chat: Chat) -> MessageViewModel {
        if viewModels.keys.contains(chat), let viewModel = viewModels[chat] {
            return viewModel
        } else {
            let viewModel = MessageViewModel(chat: chat)
            viewModels[chat] = viewModel
            return viewModel
        }
    }
}
