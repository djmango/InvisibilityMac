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
    @State private var showScrollToBottomButton = false
    @State var isFirstLoad: Bool = true
    @State private var scrollViewHeight: CGFloat = .zero
    @State var previousViewOffset: CGFloat = .zero
    let minimumOffset: CGFloat = 16 // Optional
    @State private var contentHeight: CGFloat = .zero
    @State private var outsideHeight: CGFloat = .zero

    private var displayedMessages: [APIMessage] {
        viewModel.api_messages_in_chat.suffix(numMessagesDisplayed)
    }

    var body: some View {
        GeometryReader { outsideProxy in
            ScrollViewReader { scrollProxy in
                Spacer()
                ZStack(alignment: .bottom) {
                    ScrollView {
                        contentView
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                                }
                            )
                            .background(
                                GeometryReader {
                                    Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                                })
                            .onPreferenceChange(ViewOffsetKey.self) {
                                if viewModel.isGenerating {
                                    return
                                }
                                let offsetDifference: CGFloat = self.previousViewOffset - $0
                                if abs(offsetDifference) > minimumOffset { // This condition is optional but the scroll direction is often too sensitive without a minimum offset.
                                    if !isFirstLoad {
                                        showScrollToBottomButton = $0 < contentHeight - outsideHeight - minimumOffset
                                        self.previousViewOffset = $0
                                    }
                                }
                            }
                    }
                    .coordinateSpace(name: "scroll")
                    .defaultScrollAnchor(.bottom)
                    .background(Rectangle().fill(Color.white.opacity(0.001)))
                    .frame(height: min(max(contentHeight, 100), outsideProxy.size.height))
                    .onChange(of: viewModel.isGenerating) {
                        if viewModel.isGenerating {
                            scrollToBottom(proxy: scrollProxy)
                        }
                    }
                    .onChange(of: viewModel.isRecording) {
                        if viewModel.isRecording { scrollToBottom(proxy: scrollProxy) }
                    }
                    .onChange(of: viewModel.shouldScrollToBottom) {
                        if viewModel.shouldScrollToBottom {
                            scrollToBottom(proxy: scrollProxy)
                            viewModel.shouldScrollToBottom = false
                        }
                    }
                    .onChange(of: viewModel.chat) {
                        numMessagesDisplayed = 10
                        print("Chat changed, numMessagesDisplayed reset to 10")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            scrollToBottom(proxy: scrollProxy)
                        }
                    }

                    VStack {
                        Spacer()
                        MessageButtonItemView(label: nil, icon: "arrow.down", shortcut_hint: nil, action: {
                            scrollToBottom(proxy: scrollProxy)
                        })
                    }
                    .padding(.bottom, 20)
                    .transition(.opacity)
                    .visible(if: showScrollToBottomButton)
                }
            }
            .onAppear {
                outsideHeight = outsideProxy.size.height
                DispatchQueue.main.async {
                    isFirstLoad = false
                }
            }
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
            self.contentHeight = height
        }
    }

    private var contentView: some View {
        VStack {
            HeaderView(numMessagesDisplayed: $numMessagesDisplayed)

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
                .visible(if: displayedMessages.isEmpty && viewModel.canSendMessages && !viewModel.isShowingWhatsNew, removeCompletely: true)

            CaptureView()
                .visible(if: viewModel.isRecording, removeCompletely: true)

            WhatsNewCardView()
                .visible(if: viewModel.isShowingWhatsNew, removeCompletely: true)

            Rectangle()
                .hidden()
                .frame(height: 1)
                .id("bottom")
        }
        .padding(.top, 10)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        showScrollToBottomButton = false
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
