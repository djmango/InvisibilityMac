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

    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                MessageListView(
                    messages: messageViewModel.api_messages_in_chat,
                    isRecording: $screenRecorder.isRunning
                )
                .rotationEffect(.degrees(180))
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
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: messageViewModel.isGenerating) {
                if let scrollProxy, messageViewModel.isGenerating == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            scrollProxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: screenRecorder.isRunning) {
                if let scrollProxy, screenRecorder.isRunning == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            scrollProxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            // this also work for BranchManager api_message updates?
            .onChange(of: messageViewModel.shouldScrollToBottom) {
                if let scrollProxy, messageViewModel.shouldScrollToBottom {
                    print("scrolling to bottom cuz we should")
                    withAnimation(AppConfig.easeIn) {
                        scrollProxy.scrollTo("bottom", anchor: .bottom)
                        messageViewModel.shouldScrollToBottom = false
                    }
                }
            }

            .onChange(of: chatViewModel.chat) {
                // Wait .8 seconds before scrolling to the bottom to allow the chat to load
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("scrolling to bottom")
                if let scrollProxy {
                    withAnimation(AppConfig.easeIn) {
                        scrollProxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                // }
            }
            .rotationEffect(.degrees(180))
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
                whichButtonIsHovered: $whoIsHovering,
                action: { numMessagesDisplayed = 10 }
            )
            .visible(if: numMessagesDisplayed > 10, removeCompletely: true)
            .keyboardShortcut("u", modifiers: [.command, .shift])

            MessageButtonItemView(
                label: "Show +\(min(messageViewModel.api_messages_in_chat.count - numMessagesDisplayed, 10))",
                icon: "chevron.up",
                shortcut_hint: "⌘ + ⇧ + I",
                whichButtonIsHovered: $whoIsHovering,
                action: {
                    numMessagesDisplayed = min(messageViewModel.api_messages_in_chat.count, numMessagesDisplayed + 10)
                }
            )
            .visible(if: messageViewModel.api_messages_in_chat.count > 10 && numMessagesDisplayed < messageViewModel.api_messages_in_chat.count, removeCompletely: true)
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: numMessagesDisplayed)
    }
}

struct MessageListView: View {
    var messages: [APIMessage]

    @State private var numMessagesDisplayed = 10
    @State var whoIsHovered : String? = nil
    @Binding var isRecording: Bool

    @ObservedObject private var userManager = UserManager.shared

    private var displayedMessages: [APIMessage] {
        messages.suffix(numMessagesDisplayed)
    }

    var body: some View {
        VStack {
            HeaderView(numMessagesDisplayed: $numMessagesDisplayed)

            VStack(spacing: 5) {
                ForEach(displayedMessages) { message in
                    MessageListItemView(message: message, whoIsHovered: $whoIsHovered)
                        .id(message.id)
                        .sentryTrace("MessageListItemView")
                        .onHover{hovered in
                            whoIsHovered = message.id.uuidString
                        }
                }
            }
            // .background(Rectangle().fill(Color.white.opacity(0.001)))

            FreeTierCardView()
                .visible(if: !userManager.canSendMessages, removeCompletely: true)

            CaptureView()
                .visible(if: isRecording, removeCompletely: true)

            Rectangle()
                .hidden()
                .frame(height: 1)
                .id("bottom")
        }
        .animation(AppConfig.snappy, value: userManager.canSendMessages)
        .padding(.top, 10)
    }
}
