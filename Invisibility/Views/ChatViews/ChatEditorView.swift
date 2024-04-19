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

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .trailing, spacing: 0) {
                TextEditor(text: $textViewModel.text)
                    // .pasteDestination(for: URL.self) { urls in
                    //     guard let url = urls.first else { return }
                    //     MessageViewModel.shared.handleFile(url)
                    // }
                    .scrollContentBackground(.hidden)
                    .scrollIndicatorsFlash(onAppear: false)
                    .scrollIndicators(.never)
                    .multilineTextAlignment(.leading)
                    .font(.title3)
                    .padding()
                    .background(
                        // Invisible Text view to calculate height, only visible if text not too long
                        Group {
                            if textViewModel.text.count < 2000 {
                                Group {
                                    GeometryReader { geo in
                                        Text(textViewModel.text)
                                            .hidden() // Make the Text view invisible
                                            .font(.title3) // Match TextEditor font
                                            .padding() // Match TextEditor padding
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
                    .id("bottom")
            }
        }
        .defaultScrollAnchor(.bottom)
        .frame(height: max(ChatEditorView.minTextHeight, min(chatViewModel.textHeight, ChatEditorView.maxTextHeight)))
    }
}
