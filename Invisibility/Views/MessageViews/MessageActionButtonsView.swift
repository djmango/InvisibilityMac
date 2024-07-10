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
    private let message: APIMessage

    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @StateObject private var viewModel: MessageActionButtonViewModel

    @State private var isCopied: Bool = false
    @Binding private var isHovered: Bool

    @AppStorage("shortcutHints") private var shortcutHints = true

    private var isAssistant: Bool {
        message.role == .assistant
    }

    private var isGenerating: Bool {
        viewModel.isGenerating && (message.text.isEmpty)
    }

    private var isResizeButtonVisible: Bool {
        isHovered && isAssistant
    }

    private var isCopyButtonVisible: Bool {
        isHovered || (shortcutHints && shortcutViewModel.isCommandPressed)
    }

    private var isRegenerateButtonVisible: Bool {
        (isHovered && message.role == .assistant) || (shortcutHints && shortcutViewModel.isCommandPressed)
    }

    init(
        message: APIMessage,
        isHovered: Binding<Bool>
    ) {
        self.message = message
        self._isHovered = isHovered
        self._viewModel = StateObject(wrappedValue: MessageActionButtonViewModel(message: message))
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack(alignment: .trailing) {
            Spacer()

            HStack {
                Spacer()
                regenerateButton
                    .visible(if: isRegenerateButtonVisible, removeCompletely: true)

                copyButton
                    .visible(if: isCopyButtonVisible)
            }
        }
        .padding(8)
    }
    
    var regenerateButton: some View {
        MessageButtonItemView(
            label: "Regenerate",
            icon: "arrow.clockwise",
            shortcut_hint: "⌘ ⇧ R"
        ) {
            viewModel.regenerate()
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
    }
    
    var copyButton: some View {
        MessageButtonItemView(
            label: "Copy",
            icon: isCopied ? "checkmark" : "square.on.square",
            shortcut_hint: "⌘ ⌥ C"
        ) {
            copyAction()
        }
        .keyboardShortcut("c", modifiers: [.command, .option])
        .changeEffect(.jump(height: 10), value: isCopied)
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
}
