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

    @State private var whoIsHovering: String?

    var body: some View {
        HStack {
            Spacer()
            HStack {
                // Screenshot
                MessageButtonItemView(
                    label: "Screenshot",
                    icon: "text.viewfinder",
                    whoIsHovering: $whoIsHovering
                ) {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                // Model picker
                MessageButtonItemView(
                    label: llmManager.model.human_name,
                    icon: "sparkles",
                    whoIsHovering: $whoIsHovering
                ) {
                    // Claud-3 Opus -> GPT-4 ->
                    if llmManager.model == LLMModels.gpt4 {
                        llmManager.model = LLMModels.claude3_opus
                    } else {
                        llmManager.model = LLMModels.gpt4
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
                .buttonStyle(.plain)

                // Clear Chat
                MessageButtonItemView(
                    label: "Clear Chat",
                    icon: "rays",
                    whoIsHovering: $whoIsHovering
                ) {
                    messageViewModel.clearChat()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .keyboardShortcut(.delete, modifiers: [.command, .shift])

                MessageButtonItemView(
                    label: windowManager.resized ? "Shrink" : "Expand",
                    icon: windowManager.resized ? "arrow.left" : "arrow.right",
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
            .padding(.top, 7)
            .padding(.bottom, 10)
            .focusable(false)
            Spacer()
        }
        .animation(.snappy, value: whoIsHovering)
        .animation(.snappy, value: llmManager.model)
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    @MainActor
    private func resizeAction() {
        windowManager.resizeWindow()
    }
}
