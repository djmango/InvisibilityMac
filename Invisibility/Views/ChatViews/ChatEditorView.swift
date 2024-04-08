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

    @State private var previousText: String = ""
    @State private var lastTextHeight: CGFloat = 0

    private var action: () -> Void

    private static let maxTextHeight: CGFloat = 500

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .trailing, spacing: 0) {
                TextEditor(text: $chatViewModel.text)
                    .scrollContentBackground(.hidden)
                    .scrollIndicatorsFlash(onAppear: false)
                    .scrollIndicators(.never)
                    .multilineTextAlignment(.leading)
                    .font(.title3)
                    .padding()
                    .onChange(of: chatViewModel.text) {
                        handleTextChange()
                    }
                    .background(
                        // Invisible Text view to calculate height, only visible if text not too long
                        Group {
                            if chatViewModel.text.count < 2000 {
                                Group {
                                    GeometryReader { geo in
                                        Text(chatViewModel.text)
                                            .hidden() // Make the Text view invisible
                                            .font(.title3) // Match TextEditor font
                                            .padding() // Match TextEditor padding
                                            .onChange(of: chatViewModel.text) {
                                                if geo.size.height != lastTextHeight {
                                                    self.chatViewModel.textHeight = geo.size.height
                                                    self.lastTextHeight = geo.size.height
                                                }
                                            }
                                            .onAppear {
                                                self.chatViewModel.textHeight = geo.size.height
                                                self.lastTextHeight = geo.size.height
                                            }
                                    }
                                    .hidden()
                                }
                            } else {
                                Group {
                                    Text("")
                                        .onAppear {
                                            self.chatViewModel.textHeight = ChatEditorView.maxTextHeight
                                            self.lastTextHeight = ChatEditorView.maxTextHeight
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
        .frame(height: max(52, min(chatViewModel.textHeight, ChatEditorView.maxTextHeight)))
    }

    private func handleTextChange() {
        // Check for newlines in the added text
        let startIndex: String.Index = if previousText.count < chatViewModel.text.count {
            chatViewModel.text.index(chatViewModel.text.startIndex, offsetBy: previousText.count)
        } else {
            chatViewModel.text.endIndex
        }

        let addedText = String(chatViewModel.text[startIndex...])

        if addedText.contains("\n") {
            // Attempt to detect Shift key
            // We have to make sure its not a paste with a newline too
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == false, NSApp.currentEvent?.modifierFlags.contains(.command) == false {
                // If Shift is not pressed, and a newline is added, submit
                chatViewModel.text = chatViewModel.text.trimmingCharacters(in: .newlines) // Optional: remove the newline
                action()
                DispatchQueue.main.async {
                    chatViewModel.textHeight = 52 // Reset height
                }
            }
            // If Shift is pressed, just allow the newline (normal behavior) and scroll to the bottom
            // For some reason this actually works how its supposed to, only scrolling to bottom if we are at bottom, actually keeping the newline in view no matter where we are
        }
        previousText = chatViewModel.text // Update previous text state for next change
    }
}
