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

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    private let screenshotManager = ScreenshotManager.shared

    @State private var whoIsHovering: String?

    var body: some View {
        HStack {
            // Screenshot
            MessageButtonItemView(label: "Screenshot", icon: "text.viewfinder") {
                screenshotManager.capture()
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Screenshot"
                } else {
                    whoIsHovering = nil
                }
            }

            // Search Audio
            // MessageButtonItemView(label: "Search Audio", icon: "waveform") {
            //     logger.debug("Search Audio")
            // }
            // .onHover { hovering in
            //     if hovering {
            //         whoIsHovering = "Search Audio"
            //     } else {
            //         whoIsHovering = nil
            //     }
            // }

            // Record
            Button(action: {
                screenRecorder.toggleRecording()
            }
            ) {
                HStack(spacing: 0) {
                    Image(systemName: "record.circle")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(screenRecorder.isRunning ? .red : Color("ChatButtonForegroundColor"))
                        .padding(8)

                    Text(screenRecorder.isRunning ? "Recording" : "Record")
                        .font(.title3)
                        .foregroundColor(screenRecorder.isRunning ? .red : Color("ChatButtonForegroundColor"))
                        .hide(if: whoIsHovering ?? "" != "Record", removeCompletely: true)
                        .padding(.trailing, 8)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 100))
            .onTapGesture {
                screenRecorder.toggleRecording()
            }
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Record"
                } else {
                    whoIsHovering = nil
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .animation(.snappy, value: whoIsHovering)
            .animation(.snappy, value: screenRecorder.isRunning)
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            // Clear Chat
            MessageButtonItemView(label: "Clear Chat", icon: "eraser") {
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
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 21)
                .padding(.horizontal, -10)
                .padding(.vertical, -5)
                .animation(.snappy, value: whoIsHovering)
        )
        .padding(.top, 7)
        .padding(.bottom, 10)
        .focusable(false)
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }
}
