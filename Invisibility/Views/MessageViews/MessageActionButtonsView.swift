//
//  MessageActionButtonsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import PostHog
import SwiftUI
import ViewCondition

struct MessageActionButtonsView: View {
    private let message: APIMessage

    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @StateObject private var viewModel: MessageActionButtonViewModel

    @State private var isCopied: Bool = false
    @State private var buttonSize: CGFloat = 14
    @Binding private var isHovered: Bool
    @State private var isUpvoted: Bool?

    @AppStorage("shortcutHints") private var shortcutHints = true
    @AppStorage("token") private var token: String?

    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MessageActionButtonsView")

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
        (isHovered && message.role == .assistant) || (shortcutHints && shortcutViewModel.isCommandPressed && message.role == .assistant)
    }

    init(
        message: APIMessage,
        isHovered: Binding<Bool>
    ) {
        self.message = message
        self._isHovered = isHovered
        self._viewModel = StateObject(wrappedValue: MessageActionButtonViewModel(message: message))
        self._isUpvoted = State(initialValue: message.upvoted)
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Spacer()

            HStack {
                Spacer()
                buttonsRow
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(nsColor: .separatorColor))
                    )
                    .background(
                        VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                    )
            }
        }
        .visible(if: isHovered)
        .padding(9)
        .padding(.bottom, -19)
        .padding(.trailing, -8)
    }

    var buttonsRow: some View {
        HStack {
            regenerateButton
                .visible(if: message.role == .assistant, removeCompletely: true)
            copyButton
            upvoteButton
                .visible(if: message.role == .assistant, removeCompletely: true)
            downvoteButton
                .visible(if: message.role == .assistant, removeCompletely: true)
        }
    }

    var regenerateButton: some View {
        MessageActionButtonItemView(
            label: "Retry",
            icon: "arrow.clockwise",
            iconColor: .primary,
            size: buttonSize
        ) {
            viewModel.regenerate()
        }
    }

    var copyButton: some View {
        MessageActionButtonItemView(
            label: message.role == .assistant ? "Copy" : nil,
            icon: isCopied ? "checkmark" : "square.on.square",
            iconColor: .primary,
            size: buttonSize
        ) {
            copyAction()
        }
        .changeEffect(.jump(height: 10), value: isCopied)
    }

    var upvoteButton: some View {
        MessageActionButtonItemView(
            label: nil,
            icon: isUpvoted == true ? "hand.thumbsup.fill" : "hand.thumbsup",
            iconColor: .primary,
            size: buttonSize
        ) {
            isUpvoted = true
            message.upvoted = true

            defer { PostHogSDK.shared.capture("upvote_message") }

            // PUT /messages/message_id/upvote
            Task {
                guard let url = URL(string: AppConfig.invisibility_api_base + "/messages/\(message.id)/upvote") else {
                    return
                }
                guard let token else {
                    logger.warning("No token for upvote")
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                let (data, _) = try await URLSession.shared.data(for: request)

                logger.debug(String(data: data, encoding: .utf8) ?? "No data")
            }
        }
    }

    var downvoteButton: some View {
        MessageActionButtonItemView(
            label: nil,
            icon: isUpvoted == false ? "hand.thumbsdown.fill" : "hand.thumbsdown",
            iconColor: .primary,
            size: buttonSize
        ) {
            isUpvoted = false
            message.upvoted = false

            defer { PostHogSDK.shared.capture("downvote_message") }

            // PUT /messages/message_id/upvote
            Task {
                guard let url = URL(string: AppConfig.invisibility_api_base + "/messages/\(message.id)/downvote") else {
                    return
                }
                guard let token else {
                    logger.warning("No token for upvote")
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                let (data, _) = try await URLSession.shared.data(for: request)

                logger.debug(String(data: data, encoding: .utf8) ?? "No data")
            }
        }
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
