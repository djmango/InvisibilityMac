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
    private let message: Message

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
        messageViewModel.isGenerating && (message.content?.isEmpty ?? true)
    }

    private var isResizeButtonVisible: Bool {
        isHovered && isAssistant
    }

    private var isCopyButtonVisible: Bool {
        (isHovered && !isGenerating) || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command))
    }

    private var isRegenerateButtonVisible: Bool {
        (isHovered && isLastMessage) || (shortcutHints && shortcutViewModel.modifierFlags.contains(.command) && isLastMessage)
    }

    private var isLastMessage: Bool {
        message.id == messageViewModel.messages.last?.id
    }

    init(
        message: Message,
        isHovered: Binding<Bool>
    ) {
        self.message = message
        self._isHovered = isHovered
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Spacer()

            // Regenerate and copy button
            HStack {
                Spacer()
                MessageButtonItemView(
                    label: "Regenerate",
                    icon: "arrow.clockwise",
                    shortcut_hint: "⌘ R",
                    whoIsHovering: $whoIsHovering
                ) {
                    regenerateAction()
                }
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                .keyboardShortcut("r", modifiers: [.command])

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
                .visible(if: isCopyButtonVisible, removeCompletely: true)
            }
        }
        .padding(8)
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: isHovered)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
    }

    // MARK: - Actions

    private func copyAction() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(message.content ?? "", forType: .string)

        isCopied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }

    private func regenerateAction() {
        Task {
            await messageViewModel.regenerate()
        }
    }
}
