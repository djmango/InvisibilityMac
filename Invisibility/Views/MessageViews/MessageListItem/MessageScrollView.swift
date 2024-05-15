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
    @ObservedObject private var shortcutViewModel: ShortcutViewModel = ShortcutViewModel.shared
    @ObservedObject private var screenRecorder: ScreenRecorder = ScreenRecorder.shared
    @ObservedObject private var userManager = UserManager.shared

    @State private var opacity: Double = 0.0
    @State private var offset = CGPoint.zero
    @State private var visibleRatio = CGFloat.zero
    @State private var whoIsHovering: String?
    @State var scrollProxy: ScrollViewProxy?

    @State var numMessagesDisplayed = 10
    private var displayedMessages: [Message] {
        messageViewModel.messages.suffix(numMessagesDisplayed)
    }

    private var showingAllMessages: Bool {
        numMessagesDisplayed >= messageViewModel.messages.count
    }

    func handleOffset(_ scrollOffset: CGPoint, visibleHeaderRatio: CGFloat) {
        self.offset = scrollOffset
        self.visibleRatio = visibleHeaderRatio
    }

    var body: some View {
        let _ = Self._printChanges()
        ScrollViewReader { proxy in
            ScrollViewWithStickyHeader(
                header: {
                    // TODO: Refactor this into its own view
                    Rectangle().hidden()

                    HStack {
                        // Collapse and expand buttons
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
                            label: "Show +\(min(messageViewModel.messages.count - numMessagesDisplayed, 10))",
                            icon: "chevron.up",
                            shortcut_hint: "⌘ + ⇧ + I",
                            whoIsHovering: $whoIsHovering,
                            action: {
                                numMessagesDisplayed = min(messageViewModel.messages.count, numMessagesDisplayed + 10)
                            }
                        )
                        .visible(if: messageViewModel.messages.count > 10 && !showingAllMessages, removeCompletely: true)
                        .keyboardShortcut("i", modifiers: [.command, .shift])
                    }
                    .animation(AppConfig.snappy, value: whoIsHovering)
                    .animation(AppConfig.snappy, value: numMessagesDisplayed)
                },
                // These magic numbers are not perfect, esp the 7 but it works ok for now
                headerHeight: messageViewModel.messages.count > 7 ? 50 : max(10, messageViewModel.windowHeight - 205),
                headerMinHeight: 0,
                onScroll: handleOffset
            ) {
                VStack(alignment: .trailing, spacing: 5) {
                    ForEach(displayedMessages) { message in
                        // Generate the view for the individual message.
                        MessageListItemView(message: message)
                            .id(message.id)
                            .sentryTrace("MessageListItemView")
                    }

                    FreeTierCardView()
                        .visible(if: !userManager.canSendMessages, removeCompletely: true)

                    CaptureView()
                        .visible(if: screenRecorder.isRunning, removeCompletely: true)

                    Rectangle()

                        .hidden()
                        .frame(height: 1)
                        .id("bottom")
                }
                .background(Rectangle().fill(Color.white.opacity(0.001)))
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
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: messageViewModel.isGenerating) {
                if let scrollProxy, messageViewModel.isGenerating == true {
                    // Only scroll if we are far away from the bottom
                    // TODO: implement a "scroll lock" where we determine if we are away from the bottom and then force the scroll
                    // scrollProxy.scrollTo(messageViewModel.messages.last?.id, anchor: .bottom)
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
}
