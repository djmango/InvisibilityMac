//
//  ModelWarmer.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/13/24.
//

import Combine
import Foundation
import OllamaKit
import SwiftUI

/// Singleton to keep the model warm
class ModelWarmer: ObservableObject {
    /// Singleton instance
    static let shared = ModelWarmer()
    /// Var to hold the selected model
    @AppStorage("selectedModel") private var selectedModel = "mistral:latest"

    enum GenerationResult {
        case success(Bool)
        case failure(Bool)
    }

    func runGeneration() async -> GenerationResult {
        await withCheckedContinuation { _ in
        }
    }

    func warm() async {
        print("Warming model")

        if await OllamaKit.shared.reachable() {
            var generation: AnyCancellable? = nil

            guard let message = Message(content: "Say nothing", role: .user).toChatMessage() else { return }
            let data = OKChatRequestData(
                model: selectedModel,
                messages: [message]
            )

            generation = OllamaKit.shared.chat(data: data)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure:
                            break
                        }
                        generation?.cancel()
                    },
                    receiveValue: { _ in
                        generation?.cancel()
                    }
                )
        }
    }
}
