//
//  ShortcutViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import AppKit
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

    private init() {}

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
                    print("Scrolling to bottom")
                    MessageViewModel.shared.shouldScrollToBottom = true
                }
            }
            .keyboardShortcut("j", modifiers: [.command])
        }

        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button("Invisibility Help") {
                NSWorkspace.shared.open(URL(string: "https://help.invisibility.so")!)
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }
}
