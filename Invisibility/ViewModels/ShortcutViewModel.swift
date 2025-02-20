//
//  ShortcutViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import AppKit
import Combine
import Foundation
import KeyboardShortcuts
import OSLog
import SwiftUI

extension KeyboardShortcuts.Name {
    // Default shortcuts with better documentation
    static let summon = Self("summon", default: .init(.space, modifiers: [.option]))
    static let screenshot = Self("screenshot", default: .init(.one, modifiers: [.command, .shift]))
    static let record = Self("record", default: .init(.two, modifiers: [.command, .shift]))
    static let clearChat = Self("clearChat", default: .init(.k, modifiers: [.command]))
    static let focusChat = Self("focusChat", default: .init(.return, modifiers: [.command]))
    static let toggleHistory = Self("toggleHistory", default: .init(.h, modifiers: [.command]))
}

struct ShortcutInfo {
    let name: String
    let description: String
    let shortcut: KeyboardShortcuts.Name
}

final class ShortcutViewModel: ObservableObject {
    static let shared = ShortcutViewModel()
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "ShortcutViewModel")

    @Published public var isCommandPressed: Bool = false
    @Published public var lastUsedShortcut: String = ""
    @Published public var showShortcutFeedback: Bool = false
    
    private var feedbackTimer: Timer?
    
    // Comprehensive list of all shortcuts with descriptions
    let availableShortcuts: [ShortcutInfo] = [
        ShortcutInfo(
            name: "Summon",
            description: "Show/hide the main window",
            shortcut: .summon
        ),
        ShortcutInfo(
            name: "Screenshot",
            description: "Capture and process a screenshot",
            shortcut: .screenshot
        ),
        ShortcutInfo(
            name: "Record",
            description: "Start/stop screen recording",
            shortcut: .record
        ),
        ShortcutInfo(
            name: "Clear Chat",
            description: "Clear current chat history",
            shortcut: .clearChat
        ),
        ShortcutInfo(
            name: "Focus Chat",
            description: "Focus on chat input field",
            shortcut: .focusChat
        ),
        ShortcutInfo(
            name: "Toggle History",
            description: "Show/hide chat history",
            shortcut: .toggleHistory
        )
    ]

    private init() {}

    @MainActor
    /// Set up the global keyboard shortcuts with visual feedback
    public func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summon) { [weak self] in
            self?.showFeedback(for: "Summon")
            if WindowManager.shared.windowIsOnScreenWithCursor {
                Task {
                    WindowManager.shared.toggleWindow()
                }
            } else {
                WindowManager.shared.positionWindowOnCursorScreen()
                Task {
                    WindowManager.shared.showWindow()
                }
            }
        }

        KeyboardShortcuts.onKeyUp(for: .screenshot) { [weak self] in
            self?.showFeedback(for: "Screenshot")
            Task { await ScreenshotManager.shared.capture() }
            WindowManager.shared.positionWindowOnCursorScreen()
        }

        KeyboardShortcuts.onKeyUp(for: .record) { [weak self] in
            self?.showFeedback(for: "Record")
            ScreenRecorder.shared.toggleRecording()
        }
        
        KeyboardShortcuts.onKeyUp(for: .clearChat) { [weak self] in
            self?.showFeedback(for: "Clear Chat")
            ChatViewModel.shared.clearCurrentChat()
        }
        
        KeyboardShortcuts.onKeyUp(for: .focusChat) { [weak self] in
            self?.showFeedback(for: "Focus Chat")
            ChatFieldViewModel.shared.focusTextField()
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleHistory) { [weak self] in
            self?.showFeedback(for: "Toggle History")
            MainWindowViewModel.shared.toggleHistory()
        }
    }
    
    private func showFeedback(for shortcutName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.lastUsedShortcut = shortcutName
            self?.showShortcutFeedback = true
            
            self?.feedbackTimer?.invalidate()
            self?.feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                self?.showShortcutFeedback = false
            }
        }
    }
    
    func getShortcutDescription(for name: String) -> String? {
        availableShortcuts.first { $0.name == name }?.description
    }
}

/// The app specific shortcuts, non-global
extension ShortcutViewModel {
    func handleAppShortcut(_ event: NSEvent) -> Bool {
        // Handle app-specific shortcuts here
        return false
    }
}
