//
//  ToolbarView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/23/24.
//

import OllamaKit
import os
import SwiftUI

struct ToolbarView: ToolbarContent {
    private let logger = Logger(subsystem: "ai.grav.app", category: "ToolbarView")

    @StateObject private var tabViewModel = TabViewModel.shared
    @StateObject private var audioPlayerViewModel = AudioPlayerViewModel.shared
    @State private var isRestarting = false

    var messageViewModel: MessageViewModel? {
        guard let selectedChat = CommandViewModel.shared.selectedChat else {
            return nil
        }
        return MessageViewModelManager.shared.viewModel(for: selectedChat)
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

            if audioPlayerViewModel.audio != nil {
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

                if audioPlayerViewModel.player != nil {
                    Button(action: {
                        audioPlayerViewModel.stop()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Stop")
                }
            }
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
                if let url = URL(string: "mailto:sulaiman@grav.ai") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Help", systemImage: "questionmark.circle")
            }
            .buttonStyle(.accessoryBar)
            .help("Help")

            Button(action: {
                isRestarting = true
                Task {
                    do {
                        try await OllamaKit.shared.waitForAPI(restart: true)
                        isRestarting = false
                    } catch {
                        AlertManager.shared.doShowAlert(title: "Error", message: "Could not restart models. Please try again.")
                    }
                }
            }) {
                Label("Restart Models", systemImage: "arrow.clockwise")
                    .rotationEffect(.degrees(isRestarting ? 360 : 0))
                    .animation(isRestarting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRestarting)
            }
            .buttonStyle(.accessoryBar)
            .help("Restart Models")

            Button(action: {
                if let chat = CommandViewModel.shared.getOrCreateChat() {
                    MessageViewModelManager.shared.viewModel(for: chat).openFile()
                } else {
                    logger.error("Could not create chat")
                }
            }) {
                Label("Open File", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.accessoryBar)
            .help("Open File (⌘ + O)")
        }
    }
}
