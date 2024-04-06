//
//  MessageActionButtonsView.swift
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
    @Binding private var isHovered: Bool
    @Binding private var isCopied: Bool
    @AppStorage("shortcutHints") private var shortcutHints = true
    @ObservedObject var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    private var isAssistant: Bool {
        message.role == .assistant
    }

    private var isGenerating: Bool {
        MessageViewModel.shared.isGenerating && (message.content?.isEmpty ?? true)
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
        message.id == MessageViewModel.shared.messages.last?.id
    }

    let regenerateAction: () -> Void
    let copyAction: () -> Void

    init(
        message: Message,
        isHovered: Binding<Bool>,
        isCopied: Binding<Bool>,
        regenerateAction: @escaping () -> Void,
        copyAction: @escaping () -> Void
    ) {
        self.message = message
        self._isHovered = isHovered
        self._isCopied = isCopied
        self.regenerateAction = regenerateAction
        self.copyAction = copyAction
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
                    shortcut_hint: "⌘ ⇧ R",
                    whoIsHovering: $whoIsHovering
                ) {
                    regenerateAction()
                }
                .visible(if: isRegenerateButtonVisible, removeCompletely: true)
                .keyboardShortcut("r", modifiers: [.command, .shift])

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
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: isHovered)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
        .padding(8)
    }
}
