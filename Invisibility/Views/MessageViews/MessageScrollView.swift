//
//  MessageScrollView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageScrollView: View {
    @ObservedObject private var viewModel: MessageScrollViewModel = .shared

    @State private var numMessagesDisplayed = 10

    private var displayedMessages: [APIMessage] {
        viewModel.api_messages_in_chat.suffix(numMessagesDisplayed)
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

                    FreeTierCardView()
                        .visible(if: !viewModel.canSendMessages, removeCompletely: true)

                    CaptureView()
                        .visible(if: viewModel.isRecording, removeCompletely: true)

                    Rectangle()
                        .hidden()
                        .frame(height: 1)
                        .id("bottom")
                }
                .animation(AppConfig.snappy, value: viewModel.canSendMessages)
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
            .onChange(of: viewModel.isGenerating) {
                if viewModel.isGenerating == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: viewModel.isRecording) {
                if viewModel.isRecording == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AppConfig.easeIn) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            // this also work for BranchManager api_message updates?
            .onChange(of: viewModel.shouldScrollToBottom) {
                if viewModel.shouldScrollToBottom {
                    // print("scrolling to bottom cuz we should")
                    withAnimation(AppConfig.easeIn) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                        viewModel.shouldScrollToBottom = false
                    }
                }
            }

            .onChange(of: viewModel.chat) {
                // Wait before scrolling to the bottom to allow the chat to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // print("scrolling to bottom")
                    withAnimation(AppConfig.easeIn) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .animation(AppConfig.snappy, value: viewModel.api_messages_in_chat)
            .background(Rectangle().fill(Color.white.opacity(0.001)))
        }
    }
}
