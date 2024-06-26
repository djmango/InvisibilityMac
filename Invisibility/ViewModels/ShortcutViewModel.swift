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
    // NOTE: default keybindings are overwritten during onboarding
    static let summon = Self("summon", default: .init(.space, modifiers: [.option]))
    static let screenshot = Self("screenshot", default: .init(.one, modifiers: [.command, .shift]))
    static let record = Self("record", default: .init(.two, modifiers: [.command, .shift]))
}

final class ShortcutViewModel: ObservableObject {
    static let shared = ShortcutViewModel()

    @Published public var modifierFlags: NSEvent.ModifierFlags = []

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        setupCommandKeyObserver()
    }

    @MainActor
    /// Set up the global keyboard shortcuts
    public func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summon) {
            // If we are just changing screens, don't toggle the window
            if WindowManager.shared.windowIsOnScreenWithCursor {
                Task {
                    WindowManager.shared.toggleWindow()
                }
            } else {
                // Just move to the new screen
                WindowManager.shared.positionWindowOnCursorScreen()
                Task {
                    WindowManager.shared.showWindow()
                }
            }
        }

        KeyboardShortcuts.onKeyUp(for: .screenshot) {
            Task { await ScreenshotManager.shared.capture() }
            WindowManager.shared.positionWindowOnCursorScreen()
        }

        KeyboardShortcuts.onKeyUp(for: .record) {
            ScreenRecorder.shared.toggleRecording()
        }
    }

    private func setupCommandKeyObserver() {
        NotificationCenter.default.publisher(for: .commandKeyPressed)
            .sink { [weak self] notification in
                if let isPressed = notification.userInfo?["isPressed"] as? Bool {
                    self?.updateModifierFlags(isCommandPressed: isPressed)
                }
            }
            .store(in: &cancellables)
    }

    private func updateModifierFlags(isCommandPressed: Bool) {
        if isCommandPressed {
            modifierFlags.insert(.command)
        } else {
            modifierFlags.remove(.command)
        }
    }
}

/// The app specific shortcuts, non-global
struct AppMenuCommands: Commands {
    var body: some Commands {
        CommandMenu("File") {
            Button("New") {
                DispatchQueue.main.async {
                    ChatViewModel.shared.newChat()
                }
            }
            .keyboardShortcut("n")
            .keyboardShortcut(.delete, modifiers: [.command, .shift])

            Button("Open") {
                InvisibilityFileManager.openFile()
            }
            .keyboardShortcut("o")

            Button("Send Message") {
                Task { await MessageViewModel.shared.sendFromChat() }
            }
            .keyboardShortcut(.return, modifiers: [.command])
        }

        CommandMenu("View") {
            Button("Scroll to Bottom") {
                DispatchQueue.main.async {
                    MessageViewModel.shared.shouldScrollToBottom = true
                }
            }
            .keyboardShortcut("j", modifiers: [.command])

            // Resize
            Button("Resize") {
                DispatchQueue.main.async {
                    WindowManager.shared.resizeWindowToggle()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button("Invisibility Help") {
                NSWorkspace.shared.open(URL(string: "https://help.invisibility.so")!)
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }
}
