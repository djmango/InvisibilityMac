//
//  MessageScrollView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import ScrollKit
import SwiftUI

struct MessageScrollView: View {
    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject private var screenRecorder: ScreenRecorder = ScreenRecorder.shared
    @ObservedObject private var userManager = UserManager.shared

    @State private var scrollProxy: ScrollViewProxy?

    @State private var numMessagesDisplayed = 10

    var body: some View {
        ScrollViewReader { proxy in
            ScrollViewWithStickyHeader(
                header: {
                    HeaderView(numMessagesDisplayed: $numMessagesDisplayed)
                },
                headerHeight: messageViewModel.api_messages_in_chat.count > 7 ? 50 : max(10, messageViewModel.windowHeight - 205),
                headerMinHeight: 0,
                onScroll: handleOffset
            ) {
                MessageListView(
                    messages: messageViewModel.api_messages_in_chat,
                    numMessagesDisplayed: $numMessagesDisplayed,
                    canSendMessages: userManager.canSendMessages,
                    isRecording: $screenRecorder.isRunning
                )
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
            .animation(AppConfig.snappy, value: numMessagesDisplayed)
            .animation(AppConfig.snappy, value: userManager.canSendMessages)
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
        }
    }

    func handleOffset(_: CGPoint, visibleHeaderRatio _: CGFloat) {
        // handling offset logic
    }
}

struct HeaderView: View {
    @Binding var numMessagesDisplayed: Int

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    @State private var whoIsHovering: String?

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
        .animation(AppConfig.snappy, value: whoIsHovering)
        .animation(AppConfig.snappy, value: numMessagesDisplayed)
    }
}

struct MessageListView: View {
    var messages: [APIMessage]
    @Binding var numMessagesDisplayed: Int
    let canSendMessages: Bool
    @Binding var isRecording: Bool

    private var displayedMessages: [APIMessage] {
        messages.suffix(numMessagesDisplayed)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            ForEach(displayedMessages) { message in
                MessageListItemView(message: message)
                    .id(message.id)
                    .sentryTrace("MessageListItemView")
            }

            FreeTierCardView()
                .visible(if: !canSendMessages, removeCompletely: true)

            CaptureView()
                .visible(if: isRecording, removeCompletely: true)
                .frame(maxHeight: 200)

            Rectangle()
                .hidden()
                .frame(height: 1)
                .id("bottom")
        }
        .background(Rectangle().fill(Color.white.opacity(0.001)))
    }
}
