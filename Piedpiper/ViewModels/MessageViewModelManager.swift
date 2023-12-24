//
//  MessageViewModelManager.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 12/23/23.
//

import Foundation
import SwiftData
import OllamaKit

class MessageViewModelManager {
    static var shared: MessageViewModelManager!
    private var viewModels: [UUID: MessageViewModel] = [:]
    private var modelContext: ModelContext
    private var ollamaKit: OllamaKit
    
    init(modelContext: ModelContext, ollamaKit: OllamaKit) {
        self.modelContext = modelContext
        self.ollamaKit = ollamaKit
    }

    func viewModel(for chatID: UUID) -> MessageViewModel {
        if let viewModel = viewModels[chatID] {
            return viewModel
        } else {
            let viewModel = MessageViewModel(chatID: chatID, modelContext: self.modelContext, ollamaKit: self.ollamaKit)
            viewModels[chatID] = viewModel
            return viewModel
        }
    }
}
