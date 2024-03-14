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

    @State private var isScreenshotHovered: Bool = false
    @State private var isModelPickerHovered: Bool = false
    @State private var isSettingsHovered: Bool = false
    @State private var isClearChatHovered: Bool = false
    @State private var isResizeHovered: Bool = false

    var body: some View {
        HStack {
            Spacer()
            HStack {
                // Screenshot
                MessageButtonItemView(
                    label: "Screenshot",
                    icon: "text.viewfinder",
                    isHovering: $isScreenshotHovered
                ) {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                .onHover { hovering in
                    if hovering {
                        messageViewModel.whoIsHovering = "Screenshot"
                    } else {
                        messageViewModel.whoIsHovering = nil
                    }
                }

                // Model picker
                MessageButtonItemView(
                    label: llmManager.model.human_name,
                    icon: "sparkles",
                    isHovering: $isModelPickerHovered
                ) {
                    // Claud-3 Opus -> GPT-4 -> Gemini Pro
                    // if llmManager.model == LLMModels.gemini_pro {
                    //     llmManager.model = LLMModels.claude3_opus
                    // } else if llmManager.model == LLMModels.claude3_opus {
                    //     llmManager.model = LLMModels.gpt4
                    // } else {
                    //     llmManager.model = LLMModels.gemini_pro
                    // }

                    // Claud-3 Opus -> GPT-4 ->
                    if llmManager.model == LLMModels.gpt4 {
                        llmManager.model = LLMModels.claude3_opus
                    } else {
                        llmManager.model = LLMModels.gpt4
                    }
                }
                .onHover { hovering in
                    if hovering {
                        messageViewModel.whoIsHovering = "Model Picker"
                    } else {
                        messageViewModel.whoIsHovering = nil
                    }
                }

                // Settings
                SettingsLink {
                    HStack(spacing: 0) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .padding(8)

                        Text("Settings")
                            .font(.title3)
                            .foregroundColor(Color("ChatButtonForegroundColor"))
                            .hide(if: messageViewModel.whoIsHovering ?? "" != "Settings", removeCompletely: true)
                            .padding(.trailing, 8)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 100))
                }
                .onHover { hovering in
                    isSettingsHovered = hovering
                    if hovering {
                        messageViewModel.whoIsHovering = "Settings"
                    } else {
                        messageViewModel.whoIsHovering = nil
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
                .animation(.snappy, value: messageViewModel.whoIsHovering)
                .buttonStyle(.plain)

                // Clear Chat
                MessageButtonItemView(
                    label: "Clear Chat",
                    icon: "rays",
                    isHovering: $isClearChatHovered
                ) {
                    messageViewModel.clearChat()
                }
                .onHover { hovering in
                    if hovering {
                        messageViewModel.whoIsHovering = "Clear Chat"
                    } else {
                        messageViewModel.whoIsHovering = nil
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .keyboardShortcut(.delete, modifiers: [.command, .shift])

                MessageButtonItemView(
                    label: windowManager.resized ? "Shrink" : "Expand",
                    icon: windowManager.resized ? "arrow.left" : "arrow.right",
                    isHovering: $isResizeHovered
                ) {
                    resizeAction()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            .animation(.snappy, value: messageViewModel.whoIsHovering)
            .animation(.snappy, value: llmManager.model)
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
                    .padding(.horizontal, -10)
                    .padding(.vertical, -5)
                    .animation(.snappy, value: messageViewModel.whoIsHovering)
            )
            .padding(.top, 7)
            .padding(.bottom, 10)
            .focusable(false)
            Spacer()
        }
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    @MainActor
    private func resizeAction() {
        windowManager.resizeWindow()
    }
}
