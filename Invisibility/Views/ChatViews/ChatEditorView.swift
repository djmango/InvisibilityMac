//
//  ChatEditorView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/8/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct ChatEditorView: View {
    @ObservedObject private var chatViewModel = ChatViewModel.shared
    @ObservedObject private var textViewModel = TextViewModel.shared

    static let minTextHeight: CGFloat = 52
    static let maxTextHeight: CGFloat = 500

    @State private var scrollPosition: String? {
        didSet {
            print("scrollPosition: \(scrollPosition ?? "nil")")
            if scrollPosition == "bottom" {
                DispatchQueue.main.async {
                    chatViewModel.textHeight = ChatEditorView.minTextHeight
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .trailing, spacing: 0) {
                TextEditor(text: $textViewModel.text)
                    .scrollContentBackground(.hidden)
                    .scrollIndicatorsFlash(onAppear: false)
                    .scrollIndicators(.never)
                    .multilineTextAlignment(.leading)
                    .font(.title3)
                    .padding()
                    .id("textEditor")
                    .background(
                        // Invisible Text view to calculate height, only visible if text not too long
                        Group {
                            if textViewModel.text.count < 3000 {
                                Group {
                                    GeometryReader { geo in
                                        Text(textViewModel.text)
                                            .hidden()
                                            .font(.title3)
                                            .padding()
                                            .onChange(of: textViewModel.text) {
                                                if geo.size.height != chatViewModel.lastTextHeight {
                                                    self.chatViewModel.textHeight = geo.size.height
                                                    self.chatViewModel.lastTextHeight = geo.size.height
                                                }
                                            }
                                            .onAppear {
                                                self.chatViewModel.textHeight = geo.size.height
                                                self.chatViewModel.lastTextHeight = geo.size.height
                                            }
                                    }
                                    .hidden()
                                }
                            } else {
                                Group {
                                    Text("")
                                        .onAppear {
                                            self.chatViewModel.textHeight = ChatEditorView.maxTextHeight
                                            self.chatViewModel.lastTextHeight = ChatEditorView.maxTextHeight
                                        }
                                        .hidden()
                                }
                            }
                        }
                    )
            }
        }
        .scrollPosition(id: $scrollPosition, anchor: .bottom)
        .frame(height: max(ChatEditorView.minTextHeight, min(chatViewModel.textHeight, ChatEditorView.maxTextHeight)))
        .defaultScrollAnchor(.bottom)
    }
}
