//
//  MessageButtonsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI
import ViewCondition

struct MessageActionButtonsView: View {
    private let message: APIMessage

    @State private var whoIsHovering: String?
    @State private var isCopied: Bool = false
    @Binding private var isHovered: Bool

    @AppStorage("shortcutHints") private var shortcutHints = true
    @ObservedObject var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModel.shared

    private var isAssistant: Bool {
        message.role == .assistant
    }

    private var isGenerating: Bool {
        messageViewModel.isGenerating && (message.text.isEmpty)
    }

    private var isResizeButtonVisible: Bool {
        isHovered && isAssistant
    }

    private var isCopyButtonVisible: Bool {
        isHovered || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command))
    }

    private var isRegenerateButtonVisible: Bool {
        (isHovered && message.role == .assistant) || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command))
    }

    init(
        message: APIMessage,
        isHovered: Binding<Bool>
    ) {
        self.message = message
        self._isHovered = isHovered
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack(alignment: .trailing) {
            Spacer()

            HStack {
                Spacer()
                MessageButtonItemView(
                    label: "Regenerate",
                    icon: "arrow.clockwise",
                    shortcut_hint: "⌘ ⇧ R",
                    whoIsHovering: $whoIsHovering
                ) {
                    regenerateAction()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)

                MessageButtonItemView(
                    label: "Copy",
                    icon: isCopied ? "checkmark" : "square.on.square",
                    shortcut_hint: "⌘ ⌥ C",
                    whoIsHovering: $whoIsHovering
                ) {
                    copyAction()
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .changeEffect(.jump(height: 10), value: isCopied)
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .visible(if: isCopyButtonVisible)
            }
        }
        .padding(8)
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
    }

    // MARK: - Actions

    private func copyAction() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(message.text, forType: .string)

        isCopied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }

    private func regenerateAction() {
        Task {
            await messageViewModel.regenerate(message: message)
        }
    }
}
