//
//  ModelWarmer.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/13/24.
//

import Combine
import Foundation
import OllamaKit
import os
import SwiftUI

/// Singleton to keep the model warm
class ModelWarmer: ObservableObject {
    let logger = Logger(subsystem: "ai.grav.app", category: "ModelWarmer")

    /// Singleton instance
    static let shared = ModelWarmer()

    /// Var to hold the selected model
    @AppStorage("selectedModel") private var selectedModel = "mistral:latest"

    func warm() async {
        logger.debug("Warming model")

        do {
            try await OllamaKit.shared.waitForAPI()
            if await OllamaKit.shared.reachable() {
                guard let message = Message(content: "Say nothing", role: .user).toChatMessage() else { return }
                let data = OKChatRequestData(
                    model: selectedModel,
                    messages: [message]
                )

                _ = try await OllamaKit.shared.achat(data: data)
            }
        } catch {
            logger.error("Error warming model: \(error)")
        }
    }
}
