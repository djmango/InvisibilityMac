//
//  MainWindowViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/7/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import PostHog
import SwiftUI

enum mainWindowView {
    case chat
    case settings
    case history
    case memory
}

import OSLog

final class MainWindowViewModel: ObservableObject {
    static let shared = MainWindowViewModel()

    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MainWindowViewModel")

    @Published var whoIsVisible: mainWindowView = .chat

    private init() {}

    /// Change the view of the main window. Returns false if the view is already visible
    @MainActor
    public func changeView(to view: mainWindowView) -> Bool {
        if view == whoIsVisible {
            return false
        }

        defer {
            if view == .chat {
                PostHogSDK.shared.capture("to_chat_view")
            } else if view == .settings {
                PostHogSDK.shared.capture("to_settings_view")
            } else if view == .history {
                PostHogSDK.shared.capture("to_history_view")
            } else if view == .memory {
                PostHogSDK.shared.capture("to_memory_view")
            }
        }

        withAnimation(AppConfig.snappy) {
            whoIsVisible = view
        }

        return true
    }

    @MainActor
    public func toggleHistory() {
        if whoIsVisible == .history {
            _ = changeView(to: .chat)
        } else {
            _ = changeView(to: .history)
        }
    }
}
