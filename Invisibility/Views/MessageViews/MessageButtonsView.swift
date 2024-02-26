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

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModelManager.shared.messageViewModel

    @State private var whoIsHovering: String?
    // @State private var selection: [Message] = []

    var body: some View {
        HStack {
            // Screenshot
            MessageButtonItemView(label: "Screenshot", icon: "text.viewfinder") {
                openFileAction()
            }
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Screenshot"
                } else {
                    whoIsHovering = nil
                }
            }

            // Search Audio
            MessageButtonItemView(label: "Search Audio", icon: "waveform") {
                logger.debug("Search Audio")
            }
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Search Audio"
                } else {
                    whoIsHovering = nil
                }
            }

            // Record
            MessageButtonItemView(label: "Record", icon: "record.circle") {
                logger.debug("Record")
            }
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Record"
                } else {
                    whoIsHovering = nil
                }
            }

            // Clear Chat
            MessageButtonItemView(label: "Clear Chat", icon: "eraser") {
                logger.debug("Clear Chat")
            }
            .onHover { hovering in
                if hovering {
                    whoIsHovering = "Clear Chat"
                } else {
                    whoIsHovering = nil
                }
            }
        }
        .animation(.snappy, value: whoIsHovering)
        .padding(.vertical, 10)
        .focusable(false)
    }

    private func openFileAction() {
        messageViewModel.openFile()
    }
}
