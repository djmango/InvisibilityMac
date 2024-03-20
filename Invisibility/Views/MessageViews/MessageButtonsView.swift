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
                    label: "Screenshot",
                    icon: "text.viewfinder",
                    shortcut_icons: ["shift", "1.square"],
                    whoIsHovering: $whoIsHovering
                ) {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                // Model picker
                MessageButtonItemView(
                    label: llmManager.model.human_name,
                    icon: "sparkles",
                    shortcut_icons: ["e.square"],
                    whoIsHovering: $whoIsHovering
                ) {
                    // Claud-3 Opus -> GPT-4 ->
                    if llmManager.model == LLMModels.gpt4 {
                        llmManager.model = LLMModels.claude3_opus
                    } else {
                        llmManager.model = LLMModels.gpt4
                    }
                }
                .keyboardShortcut("e", modifiers: [.command])

                // Settings
                SettingsLink {
                    HStack(spacing: 0) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .padding(8)
                        // .visible(if: !shortcutViewModel.modifierFlags.contains(.command), removeCompletely: true)

                        // ForEach([","], id: \.self) { icon in
                        //     Image(systemName: icon)
                        //         .resizable()
                        //         .aspectRatio(contentMode: .fit)
                        //         .frame(width: 18, height: 18)
                        //         .foregroundColor(Color("ChatButtonForegroundColor"))
                        //         .padding(8)

                        // RoundedRectangle(cornerRadius: 16)
                        //     .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        //     .overlay(
                        //         Text(",")
                        //             .font(.custom("SF Pro", size: 18))
                        //             .foregroundColor(Color("ChatButtonForegroundColor"))
                        //             .aspectRatio(contentMode: .fit)
                        //             .padding(8)
                        //     )
                        //     .frame(width: 18, height: 18)
                        //     .visible(if: shortcutViewModel.modifierFlags.contains(.command), removeCompletely: true)

                        Text("Settings")
                            .font(.title3)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .hide(if: whoIsHovering ?? "" != "Settings", removeCompletely: true)
                            .padding(.trailing, 8)
                    }
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
                    shortcut_icons: ["delete.left"],
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
                    shortcut_icons: ["p.square"],
                    whoIsHovering: $whoIsHovering
                ) {
                    messageViewModel.stopGenerating()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .visible(if: messageViewModel.isGenerating, removeCompletely: true)

                // Resize
                MessageButtonItemView(
                    label: windowManager.resized ? "Shrink" : "Expand",
                    icon: windowManager.resized ? "arrow.left" : "arrow.right",
                    shortcut_icons: ["shift", "s.square"],
                    whoIsHovering: $whoIsHovering
                ) {
                    resizeAction()
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
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    @MainActor
    private func resizeAction() {
        windowManager.resizeWindow()
    }
}
