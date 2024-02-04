//
//  ToolbarView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/23/24.
//

import os
import SwiftUI

struct ToolbarView: ToolbarContent {
    private let logger = Logger(subsystem: "ai.grav.app", category: "ToolbarView")

    @StateObject private var tabViewModel = TabViewModel.shared
    @StateObject private var audioPlayerViewModel = AudioPlayerViewModel.shared
    @StateObject private var screenRecorder = ScreenRecorder.shared

    @State private var isRestarting = false
    @State private var isCopied: Bool = false

    var messageViewModel: MessageViewModel {
        MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat)
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: {
                _ = CommandViewModel.shared.addChat()
            }) {
                Label("New Chat", systemImage: "square.and.pencil")
            }
            .buttonStyle(.accessoryBar)
            .help("New Chat (⌘ + N)")

            Button(action: {
                if screenRecorder.isRunning {
                    Task {
                        await screenRecorder.stop()
                    }
                } else {
                    Task {
                        await screenRecorder.start()
                    }
                }
            }) {
                Label(
                    screenRecorder.isRunning ? "Stop Recording" : "Start Recording",
                    systemImage: screenRecorder.isRunning ? "stop.fill" : "record.circle"
                )
                .animation(.bouncy, value: screenRecorder.isRunning)
            }
            .buttonStyle(.accessoryBar)

            Button(action: {
                if audioPlayerViewModel.isPlaying {
                    audioPlayerViewModel.pause()
                } else {
                    audioPlayerViewModel.playOrResume()
                }
            }) {
                Label(
                    audioPlayerViewModel.isPlaying ? "Pause" : "Play",
                    systemImage: audioPlayerViewModel.isPlaying ? "pause.fill" : "play.fill"
                )
                .animation(.bouncy, value: audioPlayerViewModel.isPlaying)
            }
            .buttonStyle(.accessoryBar)
            .help(audioPlayerViewModel.isPlaying ? "Pause" : "Play")
            .hide(if: audioPlayerViewModel.audio == nil, removeCompletely: true)
        }

        ToolbarItem(placement: .principal) {
            Picker("Select a tab", selection: $tabViewModel.selectedTab) {
                ForEach(0 ..< tabViewModel.tabs.count, id: \.self) { index in
                    Text(tabViewModel.tabs[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Spacer()

            Button(action: {
                if let url = URL(string: "mailto:support@grav.ai") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Help", systemImage: "questionmark.circle")
            }
            .buttonStyle(.accessoryBar)
            .help("Help")

            Button(action: copyAction) {
                Label("Copy Chat", systemImage: isCopied ? "list.clipboard.fill" : "clipboard")
            }
            .buttonStyle(.accessoryBar)
            .help("Copy Chat")

            Button(action: {
                messageViewModel.openFile()
            }) {
                Label("Open File", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.accessoryBar)
            .help("Open File (⌘ + O)")
        }
    }

    private func copyAction() {
        let pasteBoard = NSPasteboard.general

        var chatText = ""

        try? messageViewModel.fetch(for: CommandViewModel.shared.selectedChat)

        for message in messageViewModel.messages {
            if message.text.isEmpty {
                continue
            }
            chatText += message.role == .user ? "You: " : "Assistant: "
            chatText += message.text + "\n"
        }

        pasteBoard.clearContents()
        pasteBoard.setString(chatText, forType: .string)

        isCopied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }
}
