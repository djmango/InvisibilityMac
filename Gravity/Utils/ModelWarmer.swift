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
    // private var generation: AnyCancellable? = nil
    /// Var to hold last time the model was warmed
    @Published var lastWarm: Date?
    /// Var to hold the selected model
    @AppStorage("selectedModel") private var selectedModel = "mistral:latest"

    enum GenerationResult {
        case success(Bool)
        case failure(Bool)
    }

    func runGeneration() async -> GenerationResult {
        await withCheckedContinuation { continuation in
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
                            continuation.resume(returning: .failure(false))
                        case .failure:
                            continuation.resume(returning: .failure(false))
                        }
                        generation?.cancel()
                    },
                    receiveValue: { _ in
                        continuation.resume(returning: .success(true))
                        generation?.cancel()
                    }
                )
        }
    }

    func warm() async {
        print("Warming model")
        // First check the last time the model was warmed
        if let lastWarm {
            // If it was warmed in the last 60 seconds, don't warm it again
            if Date().timeIntervalSince(lastWarm) < 60 {
                print("Model was warmed in the last 60 seconds")
                return
            }
        }

        // If it wasn't warmed in the last 60 seconds, warm it
        lastWarm = Date()

        print("Sending API call")
        if await OllamaKit.shared.reachable() {
            let timeoutInterval = 15.0 // 15 seconds

            let result = await withTaskGroup(of: GenerationResult.self) { group -> GenerationResult? in
                group.async { await self.runGeneration() }
                group.async {
                    try? await Task.sleep(nanoseconds: UInt64(timeoutInterval * 1_000_000_000))
                    return .failure(false)
                }

                return await group.next()
            }

            switch result {
            case let .success(response):
                print("Generation successful with response: \(response)")
            case let .failure(error):
                print("Generation failed with error: \(error)")
                lastWarm = nil // Reset lastWarm on failure or timeout
            case nil:
                print("Generation timed out")
                lastWarm = nil // Reset lastWarm on failure or timeout
            }
        }
    }
}
