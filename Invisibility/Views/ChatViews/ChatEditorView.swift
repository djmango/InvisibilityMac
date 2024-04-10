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

    private static let minTextHeight: CGFloat = 52
    private static let maxTextHeight: CGFloat = 500

    @State private var previousText: String = ""
    @State private var lastTextHeight: CGFloat = 0

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
                    .onChange(of: textViewModel.text) {
                        handleTextChange()
                    }
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
        .frame(height: max(ChatEditorView.minTextHeight, min(chatViewModel.textHeight, ChatEditorView.maxTextHeight)))
    }

    private func handleTextChange() {
        // Check for newlines in the added text
        let startIndex: String.Index = if previousText.count < textViewModel.text.count {
            textViewModel.text.index(textViewModel.text.startIndex, offsetBy: previousText.count)
        } else {
            textViewModel.text.endIndex
        }

        let addedText = String(textViewModel.text[startIndex...])

        if addedText.contains("\n") {
            // Attempt to detect Shift key
            // We have to make sure its not a paste with a newline too
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == false, NSApp.currentEvent?.modifierFlags.contains(.command) == false {
                // If Shift is not pressed, and a newline is added, submit
                textViewModel.text = textViewModel.text.trimmingCharacters(in: .newlines) // Optional: remove the newline
                // Send chat
                Task { await MessageViewModel.shared.sendFromChat() }
                DispatchQueue.main.async {
                    chatViewModel.textHeight = ChatEditorView.minTextHeight // Reset height
                }
            }
            // If Shift is pressed, just allow the newline (normal behavior) and scroll to the bottom
            // For some reason this actually works how its supposed to, only scrolling to bottom if we are at bottom, actually keeping the newline in view no matter where we are
        }
        previousText = textViewModel.text // Update previous text state for next change
    }
}
