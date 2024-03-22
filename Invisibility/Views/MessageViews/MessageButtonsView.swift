//
//  MessageButtonsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import OSLog
import SwiftUI

struct MessageButtonsView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageListView")

    private let screenshotManager = ScreenshotManager.shared

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("resized") private var resized: Bool = false
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var windowManager: WindowManager = WindowManager.shared
    @ObservedObject private var llmManager: LLMManager = LLMManager.shared
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared

    @State private var whoIsHovering: String?

    var body: some View {
        HStack {
            Spacer()
            HStack {
                // Screenshot
                MessageButtonItemView(
                    // label: "Screenshot",
                    label: "⌘ ⇧ 1",
                    icon: "text.viewfinder",
                    shortcut_hint: "⌘ ⇧ 1",
                    whoIsHovering: $whoIsHovering
                ) {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                // Model picker
                MessageButtonItemView(
                    label: llmManager.model.human_name,
                    icon: "sparkles",
                    shortcut_hint: "⌘ E",
                    whoIsHovering: $whoIsHovering
                ) {
                    // Claud-3 Opus -> GPT-4
                    if llmManager.model == LLMModels.gpt4 {
                        llmManager.model = LLMModels.claude3_opus
                    } else {
                        llmManager.model = LLMModels.gpt4
                    }
                }
                .keyboardShortcut("e", modifiers: [.command])
                .visible(if: !betaFeatures, removeCompletely: true)

                // Settings
                SettingsLink {
                    HStack(spacing: 0) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .visible(if: !shortcutViewModel.modifierFlags.contains(.command) || !shortcutHints, removeCompletely: true)

                        Text("⌘ ,")
                            .font(.title3)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .visible(if: shortcutViewModel.modifierFlags.contains(.command) && shortcutHints, removeCompletely: true)

                        Text("Settings")
                            .font(.title3)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .visible(if: whoIsHovering ?? "" == "Settings" && animateButtons, removeCompletely: true)
                            .padding(.leading, 8)
                    }
                    .padding(8)
                    .contentShape(RoundedRectangle(cornerRadius: 100))
                }
                .onHover { hovering in
                    if hovering {
                        whoIsHovering = "Settings"
                    } else {
                        whoIsHovering = nil
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color("ChatButtonBackgroundColor"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .buttonStyle(.plain)

                // Clear Chat
                MessageButtonItemView(
                    label: "Clear Chat",
                    icon: "rays",
                    shortcut_hint: "⌘ ⇧ ⌫",
                    whoIsHovering: $whoIsHovering
                ) {
                    messageViewModel.clearChat()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .visible(if: messageViewModel.messages.count > 0, removeCompletely: true)

                // Stop generating
                MessageButtonItemView(
                    label: "Stop",
                    icon: "stop.circle.fill",
                    shortcut_hint: "⌘ P",
                    whoIsHovering: $whoIsHovering
                ) {
                    messageViewModel.stopGenerating()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .visible(if: messageViewModel.isGenerating, removeCompletely: true)

                // Resize
                MessageButtonItemView(
                    label: resized ? "Shrink" : "Expand",
                    icon: resized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.backward.and.arrow.down.forward",
                    shortcut_hint: "⌘ ⇧ B",
                    whoIsHovering: $whoIsHovering
                ) {
                    resizeAction()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])

                // Switch Sides
                MessageButtonItemView(
                    label: sideSwitched ? "Left" : "Right",
                    icon: sideSwitched ? "arrow.left" : "arrow.right",
                    shortcut_hint: "⌘ ⇧ S",
                    whoIsHovering: $whoIsHovering
                ) {
                    switchSide()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
                    .overlay(
                        RoundedRectangle(cornerRadius: 21)
                            .stroke(Color(nsColor: .separatorColor))
                    )
                    .padding(.horizontal, -10)
                    .padding(.vertical, -5)
            )
            .focusable(false)
            Spacer()
        }
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: llmManager.model)
        .animation(AppConfig.snappy, value: messageViewModel.isGenerating)
        .animation(AppConfig.snappy, value: messageViewModel.messages.count)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
        .animation(AppConfig.snappy, value: betaFeatures)
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    @MainActor
    private func resizeAction() {
        windowManager.resizeWindow()
    }

    @MainActor
    private func switchSide() {
        windowManager.switchSide()
    }
}
