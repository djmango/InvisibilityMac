//
//  MessageScrollView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageScrollView: View {
    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject private var screenRecorder: ScreenRecorder = ScreenRecorder.shared
    @ObservedObject private var userManager = UserManager.shared

    @State private var numMessagesDisplayed = 10

    private var displayedMessages: [APIMessage] {
        messageViewModel.api_messages_in_chat.suffix(numMessagesDisplayed)
    }

    var body: some View {
        // let _ = Self._printChanges()
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    HeaderView(numMessagesDisplayed: $numMessagesDisplayed)

                    Spacer()

                    VStack(spacing: 5) {
                        ForEach(displayedMessages) { message in
                            MessageListItemView(message: message)
                                .id(message.id)
                        }
                    }

                    NewChatCardView()
                        .visible(if: displayedMessages.isEmpty, removeCompletely: true)

                    FreeTierCardView()
                        .visible(if: !userManager.canSendMessages, removeCompletely: true)

                    CaptureView()
                        .visible(if: screenRecorder.isRunning, removeCompletely: true)

                    Rectangle()
                        .hidden()
                        .frame(height: 1)
                        .id("bottom")
                }
                .animation(AppConfig.snappy, value: userManager.canSendMessages)
                .padding(.top, 10)
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.005), // Finish fading in
                        .init(color: .black, location: 0.995), // Start fading out
                        .init(color: .clear, location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scrollIndicators(.never)
            .defaultScrollAnchor(.bottom)
            .onChange(of: messageViewModel.isGenerating) {
                if messageViewModel.isGenerating == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: screenRecorder.isRunning) {
                if screenRecorder.isRunning == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            // this also work for BranchManager api_message updates?
            .onChange(of: messageViewModel.shouldScrollToBottom) {
                if messageViewModel.shouldScrollToBottom {
                    // print("scrolling to bottom cuz we should")
                    withAnimation(AppConfig.easeIn) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                        messageViewModel.shouldScrollToBottom = false
                    }
                }
            }

            .onChange(of: chatViewModel.chat) {
                // Wait before scrolling to the bottom to allow the chat to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // print("scrolling to bottom")
                    withAnimation(AppConfig.easeIn) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct HeaderView: View {
    @Binding var numMessagesDisplayed: Int
    @State private var whoIsHovering: String?

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared

    var body: some View {
        HStack {
            MessageButtonItemView(
                label: "Collapse",
                icon: "chevron.down",
                shortcut_hint: "⌘ + ⇧ + U",
                whoIsHovering: $whoIsHovering,
                action: { numMessagesDisplayed = 10 }
            )
            .visible(if: numMessagesDisplayed > 10, removeCompletely: true)
            .keyboardShortcut("u", modifiers: [.command, .shift])

            MessageButtonItemView(
                label: "Show +\(min(messageViewModel.api_messages_in_chat.count - numMessagesDisplayed, 10))",
                icon: "chevron.up",
                shortcut_hint: "⌘ + ⇧ + I",
                whoIsHovering: $whoIsHovering,
                action: {
                    numMessagesDisplayed = min(messageViewModel.api_messages_in_chat.count, numMessagesDisplayed + 10)
                }
            )
            .visible(if: messageViewModel.api_messages_in_chat.count > 10 && numMessagesDisplayed < messageViewModel.api_messages_in_chat.count, removeCompletely: true)
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
        .animation(AppConfig.snappy, value: numMessagesDisplayed)
    }
}
