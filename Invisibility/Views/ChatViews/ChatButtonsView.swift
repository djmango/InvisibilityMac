//
//  ChatButtonsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import OSLog
import SwiftUI

struct ChatButtonsView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatButtonsView")

    @StateObject private var viewModel: ChatButtonsViewModel = ChatButtonsViewModel()

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    @State private var whoIsHovering: String?

    var body: some View {
        HStack(alignment: .center) {
            // New Chat
            MessageButtonItemView(
                label: "New Chat",
                icon: "plus",
                shortcut_hint: "⌘ N",
                whoIsHovering: $whoIsHovering

            ) {
                _ = viewModel.newChat()
            }
            .keyboardShortcut("n", modifiers: [.command])
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Screenshot
            MessageButtonItemView(
                label: "Screenshot",
                icon: "text.viewfinder",
                shortcut_hint: "⌘ ⇧ 1",
                whoIsHovering: $whoIsHovering

            ) {
                viewModel.captureScreenshot()
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])
            .visible(if: !viewModel.isShowingHistory, removeCompletely: true)
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Video
            MessageButtonItemView(
                label: viewModel.isRecording ? "Stop Sidekick" : "Start Sidekick",
                icon: "shared.with.you",
                shortcut_hint: "⌘ ⇧ 2",
                whoIsHovering: $whoIsHovering,
                iconColor: viewModel.isRecording ? .purple : .chatButtonForeground
            ) {
                viewModel.toggleRecording()
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])
            .visible(if: !viewModel.isShowingHistory, removeCompletely: true)
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Search Chat History
            MessageButtonItemView(
                label: "History",
                icon: "magnifyingglass",
                shortcut_hint: "⌘ F",
                whoIsHovering: $whoIsHovering,
                iconColor: viewModel.isShowingHistory ? .history : .chatButtonForeground
            ) {
                if viewModel.isShowingHistory {
                    _ = viewModel.changeView(to: .chat)
                } else {
                    _ = viewModel.changeView(to: .history)
                }
            }
            .keyboardShortcut("f", modifiers: [.command])
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Settings
            MessageButtonItemView(
                label: "Settings",
                icon: "gearshape",
                shortcut_hint: "⌘ ,",
                whoIsHovering: $whoIsHovering

            ) {
                if viewModel.whoIsVisible == .settings {
                    _ = viewModel.changeView(to: .chat)
                } else {
                    _ = viewModel.changeView(to: .settings)
                }
            }
            .keyboardShortcut(",", modifiers: [.command])
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Stop generating
            MessageButtonItemView(
                label: "Stop",
                icon: "stop.circle.fill",
                shortcut_hint: "⌘ P",
                whoIsHovering: $whoIsHovering

            ) {
                logger.info("Stop generating")
                viewModel.stopGenerating()
            }
            .keyboardShortcut("p", modifiers: [.command])
            .visible(if: viewModel.isGenerating, removeCompletely: true)
            .visible(if: !viewModel.isShowingHistory, removeCompletely: true)
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

            // Switch Sides
            MessageButtonItemView(
                label: sideSwitched ? "Left" : "Right",
                icon: sideSwitched ? "arrow.left" : "arrow.right",
                shortcut_hint: "⌘ ⇧ S",
                whoIsHovering: $whoIsHovering
            ) {
                viewModel.switchSide()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .onHover { hovered in
                if hovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
        }
        // .focusable(false)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
        )
        .frame(maxWidth: 380)
        .animation(AppConfig.snappy, value: viewModel.isGenerating)
    }
}
