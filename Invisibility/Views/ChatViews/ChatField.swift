//
//  ChatField.swift
//
//
//  Created by Sulaiman Ghori on 22/02/24.
//

import AppKit
import OSLog
import SwiftUI

/// A control that displays an editable text interface for chat purposes.
///
/// ``ChatField`` extends standard text field capabilities with multiline input and specific behaviors for different platforms.
struct ChatField: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "ChatField")

    @ObservedObject private var messageViewModel = MessageViewModel.shared
    @ObservedObject private var chatViewModel = ChatViewModel.shared

    @State private var previousText: String = ""
    @State private var whichImageIsHovering: UUID?
    @State private var lastTextHeight: CGFloat = 0

    private var action: () -> Void

    /// Creates a text field with a text label generated from a localized title string.
    ///
    /// - Parameters:
    ///   - action: The action to execute upon text submission.
    public init(
        action: @escaping () -> Void
    ) {
        self.action = action
    }

    public var body: some View {
        // Images
        VStack {
            HStack {
                ForEach(chatViewModel.images) { imageItem in
                    ChatImage(imageItem: imageItem, whichImageIsHovering: $whichImageIsHovering)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .visible(if: !chatViewModel.images.isEmpty, removeCompletely: true)

            Divider()
                .background(Color(nsColor: .separatorColor))
                .padding(.horizontal, 10)
                .visible(if: !chatViewModel.images.isEmpty, removeCompletely: true)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .trailing, spacing: 0) {
                        TextEditor(text: $chatViewModel.text)
                            .scrollContentBackground(.hidden)
                            .scrollIndicatorsFlash(onAppear: false)
                            .scrollIndicators(.never)
                            .multilineTextAlignment(.leading)
                            .font(.title3)
                            .padding()
                            .background(
                                // Invisible Text view to calculate height
                                // TODO: optimize this, maybe only have geometry reader under a certain size
                                GeometryReader { geo in
                                    Text(chatViewModel.text)
                                        .hidden() // Make the Text view invisible
                                        .font(.title3) // Match TextEditor font
                                        .padding() // Match TextEditor padding
                                        .onChange(of: chatViewModel.text) {
                                            handleTextChange(scrollView: proxy)
                                            if geo.size.height != lastTextHeight {
                                                self.chatViewModel.textHeight = geo.size.height
                                                self.lastTextHeight = geo.size.height
                                                proxy.scrollTo("bottom", anchor: .bottom)
                                            }
                                        }
                                }
                                .hidden()
                            )
                            .id("bottom")
                    }
                }
            }
            .frame(height: max(52, min(chatViewModel.textHeight, 500)))
        }
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
        .animation(.easeIn(duration: 0.2), value: chatViewModel.images)
    }

    private func handleTextChange(scrollView: ScrollViewProxy) {
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
            logger.debug("Newline detected")
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
            scrollView.scrollTo("bottom", anchor: .bottom)
        }
        previousText = chatViewModel.text // Update previous text state for next change
    }
}
