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

    @State private var isRestarting = false
    @State private var selectedTab: Int = 0

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: {
                _ = CommandViewModel.shared.addChat()
            }) {
                Label("New Chat", systemImage: "square.and.pencil")
            }
            .buttonStyle(.accessoryBar)
            .help("New Chat (⌘ + N)")
        }

        ToolbarItem(placement: .principal) {
            Picker("Select a tab", selection: $selectedTab) {
                Text("First").tag(0)
                Text("Second").tag(1)
                Text("Third").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
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
                        AlertViewModel.shared.doShowAlert(title: "Error", message: "Could not restart models. Please try again.")
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
