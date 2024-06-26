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

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var screenRecorder: ScreenRecorder = ScreenRecorder.shared
    private var mainWindowViewModel: MainWindowViewModel = MainWindowViewModel.shared
    private var chatViewModel: ChatViewModel = ChatViewModel.shared
    private var windowManager: WindowManager = WindowManager.shared
    private let screenshotManager = ScreenshotManager.shared

    private var isShowingHistory: Bool {
        mainWindowViewModel.whoIsVisible == .history
    }

    @State private var whoIsHovering: String?

    var body: some View {
        HStack(alignment: .center) {
            // New Chat
            MessageButtonItemView(
                label: "New Chat",
                icon: "plus",
                shortcut_hint: "⌘ N",
                whichButtonIsHovered: $whoIsHovering

            ) {
                withAnimation(AppConfig.snappy) {
                    chatViewModel.newChat()
                }
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            // Screenshot
            MessageButtonItemView(
                label: "Screenshot",
                icon: "text.viewfinder",
                shortcut_hint: "⌘ ⇧ 1",
                whichButtonIsHovered: $whoIsHovering

            ) {
                Task { await screenshotManager.capture() }
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])
            .visible(if: !isShowingHistory, removeCompletely: true)

            // Video
            MessageButtonItemView(
                label: screenRecorder.isRunning ? "Stop Sidekick" : "Start Sidekick",
                icon: "shared.with.you",
                shortcut_hint: "⌘ ⇧ 2",
                whichButtonIsHovered: $whoIsHovering,
                iconColor: screenRecorder.isRunning ? .purple : .chatButtonForeground
            ) {
                screenRecorder.toggleRecording()
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])
            .visible(if: !isShowingHistory, removeCompletely: true)
            
            // Search Chat History
            MessageButtonItemView(
                label: "History",
                icon: "magnifyingglass",
                shortcut_hint: "⌘ F",
                whichButtonIsHovered: $whoIsHovering,
                iconColor: isShowingHistory ? .history : .chatButtonForeground
            ) {
                if isShowingHistory {
                    _ = mainWindowViewModel.changeView(to: .chat)
                } else {
                    _ = mainWindowViewModel.changeView(to: .history)
                }
            }
            .keyboardShortcut("f", modifiers: [.command])

            // Settings
            MessageButtonItemView(
                label: "Settings",
                icon: "gearshape",
                shortcut_hint: "⌘ ,",
                whichButtonIsHovered: $whoIsHovering

            ) {
                if mainWindowViewModel.whoIsVisible == .settings {
                    _ = mainWindowViewModel.changeView(to: .chat)
                } else {
                    _ = mainWindowViewModel.changeView(to: .settings)
                }
            }
            .keyboardShortcut(",", modifiers: [.command])

            // Stop generating
            MessageButtonItemView(
                label: "Stop",
                icon: "stop.circle.fill",
                shortcut_hint: "⌘ P",
                whichButtonIsHovered: $whoIsHovering

            ) {
                logger.info("Stop generating")
                messageViewModel.stopGenerating()
            }
            .keyboardShortcut("p", modifiers: [.command])
            .visible(if: messageViewModel.isGenerating, removeCompletely: true)
            .visible(if: !isShowingHistory, removeCompletely: true)
            
            // Switch Sides
            MessageButtonItemView(
                label: sideSwitched ? "Left" : "Right",
                icon: sideSwitched ? "arrow.left" : "arrow.right",
                shortcut_hint: "⌘ ⇧ S",
                whichButtonIsHovered: $whoIsHovering
            ) {
                windowManager.switchSide()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            
        }
        .focusable(false)
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
        .animation(AppConfig.snappy, value: messageViewModel.isGenerating)
        .animation(AppConfig.snappy, value: messageViewModel.api_messages_in_chat.count)
        .animation(AppConfig.snappy, value: betaFeatures)
    }
}
