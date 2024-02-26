//
//  MessageListView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import OSLog
import SwiftUI

struct MessageListView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "MessageListView")

    @ObservedObject var messageViewModel: MessageViewModel = MessageViewModelManager.shared.messageViewModel

    @FocusState private var isEditorFocused: Bool
    @FocusState private var promptFocused: Bool

    @State private var content: String = ""
    // @State private var selection: [Message] = []

    init() {
        isEditorFocused = true
        promptFocused = true
    }

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List(messageViewModel.messages.indices, id: \.self) { index in
                let message: Message = messageViewModel.messages[index]
                // On first add spacer to top
                // if index == 0 {
                //     Spacer()
                //         .frame(maxHeight: .infinity)
                // }
                let action: () -> Void = {
                    regenerateAction(for: message)
                }

                // let audioActionPassed: () -> Void = {
                //     guard let audio = message.audio else { return }
                //     audioAction(for: audio)
                // }
                // VStack {
                //     if let audio = message.audio {
                //         AudioWidgetView(audio: audio, tapAction: audioActionPassed)
                //             .onHover { hovering in
                //                 if hovering {
                //                     NSCursor.pointingHand.push()
                //                 } else {
                //                     NSCursor.pop()
                //                 }
                //             }
                //     } else if let images = message.images {
                //         HStack(alignment: .center, spacing: 8) {
                //             ForEach(images, id: \.self) { imageData in
                //                 if let nsImage = NSImage(data: imageData) {
                //                     Image(nsImage: nsImage)
                //                         .resizable()
                //                         .scaledToFit()
                //                         .frame(maxWidth: 256, maxHeight: 384) // 2:3 aspect ratio max
                //                         .cornerRadius(8) // Rounding is strange for large images, seems to be proportional to size for some reason
                //                         .shadow(radius: 2)
                //                 }
                //             }
                //         }
                //     } else {
                // Generate the view for the individual message.
                MessageListItemView(
                    message: message,
                    messageViewModel: messageViewModel,
                    regenerateAction: action
                )
                // .generating(message.content == nil && isGenerating)
                .generating(message.content == nil)
                .finalMessage(index == messageViewModel.messages.endIndex - 1)
                .audio(message.audio)
                // }
                // }
                // .overlay(
                //     RoundedRectangle(cornerRadius: 16)
                //         .stroke(Color(nsColor: .separatorColor))
                // )
                // .padding(.horizontal, -5)
                .id(message)
                .listRowSeparator(.hidden)
            }
            // .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .onAppear {
                scrollToBottom(scrollViewProxy)
            }
            .onChange(of: messageViewModel.messages) {
                scrollToBottom(scrollViewProxy)
            }
            .onChange(of: messageViewModel.messages.last?.content) {
                scrollToBottom(scrollViewProxy)
            }
            .task {
                scrollToBottom(scrollViewProxy)
            }
        }

        ChatField(text: $content, action: sendAction)
            .focused($promptFocused)
            .onTapGesture {
                promptFocused = true
            }
            .padding(.vertical, 8)
    }

    private func sendAction() {
        guard messageViewModel.sendViewState == nil else { return }
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }

        let message = Message(content: content, role: .user)
        content = ""

        Task {
            await messageViewModel.send(message)
        }
    }

    private func regenerateAction(for message: Message) {
        Task {
            await messageViewModel.regenerate(message)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard messageViewModel.messages.count > 0 else { return }
        let lastIndex = messageViewModel.messages.count - 1
        let lastMessage = messageViewModel.messages[lastIndex]

        logger.debug("Scrolling to bottom")
        logger.debug("Last message: \(lastMessage)")

        proxy.scrollTo(lastMessage, anchor: .bottom)
    }
}
