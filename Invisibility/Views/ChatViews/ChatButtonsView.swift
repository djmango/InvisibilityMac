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

    private let screenshotManager = ScreenshotManager.shared

    @AppStorage("animateButtons") private var animateButtons: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("resized") private var resized: Bool = false
    @AppStorage("shortcutHints") private var shortcutHints: Bool = true
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var screenRecorder: ScreenRecorder = ScreenRecorder.shared
    private var windowManager: WindowManager = WindowManager.shared

    @State private var whoIsHovering: String?

    private var isDisplayingModelPicker: Bool {
        whoIsHovering == "Models"
    }

    var body: some View {
        HStack {
            Spacer()
            HStack {
                // Screenshot
                MessageButtonItemView(
                    label: "Screenshot",
                    icon: "text.viewfinder",
                    shortcut_hint: "⌘ ⇧ 1",
                    whoIsHovering: $whoIsHovering
                ) {
                    Task { await screenshotManager.capture() }
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                .hide(if: isDisplayingModelPicker, removeCompletely: true)

                // Video
                MessageButtonItemView(
                    label: screenRecorder.isRunning ? "Disable Video" : "Enable Video",
                    icon: "record.circle",
                    shortcut_hint: "⌘ ⇧ 2",
                    whoIsHovering: $whoIsHovering,
                    iconColor: screenRecorder.isRunning ? .red : Color("ChatButtonForegroundColor")
                ) {
                    screenRecorder.toggleRecording()
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])

                // Settings
                MessageButtonItemView(
                    label: "Settings",
                    icon: "gearshape",
                    shortcut_hint: "⌘ ,",
                    whoIsHovering: $whoIsHovering
                ) {
                    DispatchQueue.main.async {
                        SettingsViewModel.shared.showSettings.toggle()
                    }
                }
                .keyboardShortcut(",", modifiers: [.command])
                .hide(if: isDisplayingModelPicker, removeCompletely: true)

                // Models
                // ChatModelPicker(whoIsHovering: $whoIsHovering)

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
                .hide(if: messageViewModel.messages.count == 0, removeCompletely: true)
                .hide(if: isDisplayingModelPicker, removeCompletely: true)

                // Stop generating
                MessageButtonItemView(
                    label: "Stop",
                    icon: "stop.circle.fill",
                    shortcut_hint: "⌘ P",
                    whoIsHovering: $whoIsHovering
                ) {
                    logger.info("Stop generating")
                    messageViewModel.stopGenerating()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .visible(if: messageViewModel.isGenerating, removeCompletely: true)
                .hide(if: isDisplayingModelPicker, removeCompletely: true)

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
                .hide(if: isDisplayingModelPicker, removeCompletely: true)

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
                .hide(if: isDisplayingModelPicker, removeCompletely: true)
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
        .animation(AppConfig.snappy, value: messageViewModel.isGenerating)
        .animation(AppConfig.snappy, value: messageViewModel.messages.count)
        .animation(AppConfig.snappy, value: shortcutViewModel.modifierFlags)
        .animation(AppConfig.snappy, value: betaFeatures)
        .frame(maxWidth: resized ? 500 : 380)
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }

    @MainActor
    private func resizeAction() {
        print("Resizing window")
        windowManager.resizeWindow()
    }

    @MainActor
    private func switchSide() {
        windowManager.switchSide()
    }
}
