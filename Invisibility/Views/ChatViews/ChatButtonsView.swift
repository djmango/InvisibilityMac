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
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "ChatButtonsView")

    @StateObject private var viewModel = ChatButtonsViewModel()

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    // Selected Shortcuts
    @AppStorage("showNewChat") private var showNewChat: Bool = true
    @AppStorage("showScreenshot") private var showScreenshot: Bool = false
    @AppStorage("showSidekick") private var showSidekick: Bool = true
    @AppStorage("showHistory") private var showHistory: Bool = true
    @AppStorage("showMemory") private var showMemory: Bool = true
    @AppStorage("showSettings") private var showSettings: Bool = true
    @AppStorage("showMicrophone") private var showMicrophone: Bool = true
    @AppStorage("showSwitchSides") private var showSwitchSides: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            newChatButton
                .keyboardShortcut("n", modifiers: [.command])
                .visible(if: showNewChat, removeCompletely: true)

            audioButton
                .keyboardShortcut("t", modifiers: [.command])
                .visible(if: showMicrophone, removeCompletely: true)

            screenshotButton
                .keyboardShortcut("1", modifiers: [.command, .shift])
                .visible(if: !viewModel.isShowingHistory && showScreenshot, removeCompletely: true)

            videoButton
                .keyboardShortcut("2", modifiers: [.command, .shift])
                .visible(if: !viewModel.isShowingHistory && showSidekick, removeCompletely: true)
            
            historyButton
                .keyboardShortcut("f", modifiers: [.command])
                .visible(if: showHistory, removeCompletely: true)

            memoryButton
                .keyboardShortcut("m", modifiers: [.command])
                .visible(if: showMemory, removeCompletely: true)

            settingsButton
                .keyboardShortcut(",", modifiers: [.command])
                .visible(if: showSettings, removeCompletely: true)

            stopGeneratingButton
                .keyboardShortcut("p", modifiers: [.command])
                .visible(if: viewModel.isGenerating, removeCompletely: true)
                .visible(if: !viewModel.isShowingHistory, removeCompletely: true)
            
            switchSideButton
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .visible(if: showSwitchSides, removeCompletely: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
        )
        .animation(AppConfig.snappy, value: viewModel.isGenerating)
    }
    // MARK: - Buttons
    
    // New Chat
    var newChatButton: some View {
        MessageButtonItemView(
            label: "New Chat",
            icon: "plus",
            shortcut_hint: "⌘ N"

        ) {
            _ = viewModel.newChat()
        }
    }
    
    // Audio
    var audioButton: some View {
        MessageButtonItemView(
            label: viewModel.isTranscribing ? "Stop" : "Capture Voice",
            icon: viewModel.isTranscribing ? "stop.circle" : "mic.fill",
            shortcut_hint: "⌘ T"

        ) {
            viewModel.toggleTranscribing()
        }
    }
    
    // Screenshot
    var screenshotButton: some View {
        MessageButtonItemView(
            label: "Screenshot",
            icon: "text.viewfinder",
            shortcut_hint: "⌘ ⇧ 1"

        ) {
            viewModel.captureScreenshot()
        }
    }
    
    // Video
    var videoButton: some View {
        MessageButtonItemView(
            label: viewModel.isRecording ? "Stop Sidekick" : "Start Sidekick",
            icon: "shared.with.you",
            shortcut_hint: "⌘ ⇧ 2",
            iconColor: viewModel.isRecording ? .purple : .chatButtonForeground
        ) {
            viewModel.toggleRecording()
        }
    }
    
    // Search Chat History
    var historyButton: some View {
        MessageButtonItemView(
            label: "History",
            icon: "magnifyingglass",
            shortcut_hint: "⌘ F",
            iconColor: viewModel.isShowingHistory ? .history : .chatButtonForeground
        ) {
            if viewModel.isShowingHistory {
                _ = viewModel.changeView(to: .chat)
            } else {
                _ = viewModel.changeView(to: .history)
            }
        }
    }
    
    // Memory
    var memoryButton: some View {
        MessageButtonItemView(
            label: "Memory",
            icon: "memorychip",
            shortcut_hint: "⌘ M",
            iconColor: viewModel.isShowingMemory ? .history : .chatButtonForeground
        ) {
            if viewModel.isShowingMemory {
                _ = viewModel.changeView(to: .chat)
            } else {
                _ = viewModel.changeView(to: .memory)
            }
        }
    }
    
    // Settings
    var settingsButton: some View {
        MessageButtonItemView(
            label: "Settings",
            icon: "gearshape",
            shortcut_hint: "⌘ ,"

        ) {
            if viewModel.whoIsVisible == .settings {
                _ = viewModel.changeView(to: .chat)
            } else {
                _ = viewModel.changeView(to: .settings)
            }
        }
    }
    
    // Stop generating
    var stopGeneratingButton: some View {
        MessageButtonItemView(
            label: "Stop",
            icon: "stop.circle.fill",
            shortcut_hint: "⌘ P"

        ) {
            logger.info("Stop generating")
            viewModel.stopGenerating()
        }
    }
    
    // Switch Sides
    var switchSideButton: some View {
        MessageButtonItemView(
            label: sideSwitched ? "Left" : "Right",
            icon: sideSwitched ? "arrow.left" : "arrow.right",
            shortcut_hint: "⌘ ⇧ S"
        ) {
            viewModel.switchSide()
        }
    }
}

#Preview {
    ChatButtonsView()
}
