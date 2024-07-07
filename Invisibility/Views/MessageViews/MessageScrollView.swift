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
    @State private var scrollViewHeight: CGFloat = .zero
    @State private var contentHeight: CGFloat = .zero
    @State private var outsideHeight: CGFloat = .zero

    private var displayedMessages: [APIMessage] {
        viewModel.api_messages_in_chat.suffix(numMessagesDisplayed)
    }

    var body: some View {
        GeometryReader { outsideProxy in
            ScrollViewReader { scrollProxy in
                Spacer()
                ScrollView {
                    contentView
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        )
                }
                .frame(height: min(max(contentHeight, 100), outsideProxy.size.height))
                .onChange(of: viewModel.isGenerating) { newValue in
                    if newValue { scrollToBottom(proxy: scrollProxy) }
                }
                .onChange(of: viewModel.isRecording) { newValue in
                    if newValue { scrollToBottom(proxy: scrollProxy) }
                }
                .onChange(of: viewModel.shouldScrollToBottom) { newValue in
                    if newValue {
                        scrollToBottom(proxy: scrollProxy)
                        viewModel.shouldScrollToBottom = false
                    }
                }
                .onChange(of: viewModel.chat) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        scrollToBottom(proxy: scrollProxy)
                    }
                }
            }
            .onAppear {
                outsideHeight = outsideProxy.size.height
                print("Outside height: \(outsideHeight)")
            }
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
            self.contentHeight = height
            print("Content height updated: \(height)")
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.005),
                    .init(color: .black, location: 0.995),
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(AppConfig.snappy, value: viewModel.api_messages_in_chat)
        .background(Rectangle().fill(Color.white.opacity(0.001)))
    }

    private var contentView: some View {
        VStack {
            VStack(spacing: 5) {
                ForEach(displayedMessages) { message in
                    MessageListItemView(message: message)
                        .id(message.id)
                }
            }

            FreeTierCardView()
                .visible(if: !viewModel.canSendMessages, removeCompletely: true)
                .padding(.top, 10)

            NewChatCardView()
                .visible(if: displayedMessages.isEmpty && viewModel.canSendMessages, removeCompletely: true)

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

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(AppConfig.easeIn) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
