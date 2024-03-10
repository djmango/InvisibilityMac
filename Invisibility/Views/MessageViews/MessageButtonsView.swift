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
    @ObservedObject private var llmManager: LLMManager = LLMManager.shared
    @ObservedObject private var windowManager: WindowManager = WindowManager.shared

    @State private var whoIsHovering: String?

    var body: some View {
        HStack {
            Spacer()
            HStack {
                // Screenshot
                MessageButtonItemView(label: "Screenshot", icon: "text.viewfinder") {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                .onHover { hovering in
                    if hovering {
                        whoIsHovering = "Screenshot"
                    } else {
                        whoIsHovering = nil
                    }
                }

                // Model picker
                MessageButtonItemView(label: llmManager.model.human_name, icon: "sparkles") {
                    // Claud-3 Opus -> GPT-4 -> Gemini Pro
                    if llmManager.model == LLMModels.gemini_pro {
                        llmManager.model = LLMModels.claude3_opus
                    } else if llmManager.model == LLMModels.claude3_opus {
                        llmManager.model = LLMModels.gpt4
                    } else {
                        llmManager.model = LLMModels.gemini_pro
                    }
                }
                .onHover { hovering in
                    if hovering {
                        whoIsHovering = "Model Picker"
                    } else {
                        whoIsHovering = nil
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
                .animation(.snappy, value: whoIsHovering)
                .buttonStyle(.plain)

                // Clear Chat
                MessageButtonItemView(label: "Clear Chat", icon: "rays") {
                    messageViewModel.clearChat()
                }
                .onHover { hovering in
                    if hovering {
                        whoIsHovering = "Clear Chat"
                    } else {
                        whoIsHovering = nil
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
            }
            .animation(.snappy, value: whoIsHovering)
            .animation(.snappy, value: llmManager.model)
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
                    .padding(.horizontal, -10)
                    .padding(.vertical, -5)
                    .animation(.snappy, value: whoIsHovering)
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
}
