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

    @Binding private var text: String
    @State private var textHeight: CGFloat = 52
    @State private var previousText: String = ""
    @State private var whoIsHovering: UUID?

    private var action: () -> Void

    /// Creates a text field with a text label generated from a localized title string.
    ///
    /// - Parameters:
    ///   - text: The text to display and edit.
    ///   - action: The action to execute upon text submission.
    public init(
        text: Binding<String>,
        action: @escaping () -> Void
    ) {
        _text = text
        self.action = action
    }

    public var body: some View {
        // Images
        VStack {
            HStack {
                ForEach(chatViewModel.images) { imageItem in
                    ChatImage(imageItem: imageItem, whoIsHovering: $whoIsHovering)
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

            ScrollView {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .multilineTextAlignment(.leading)
                    .font(.title3)
                    .padding()
                    .onChange(of: text) {
                        handleTextChange()
                    }
                    .background(
                        // Invisible Text view to calculate height
                        GeometryReader { geo in
                            Text(text)
                                .font(.title3) // Match TextEditor font
                                .padding() // Match TextEditor padding
                                .hidden() // Make the Text view invisible
                                .onChange(of: text) {
                                    self.textHeight = geo.size.height
                                }
                        }
                    )
            }
            .scrollIndicators(.never)
            .frame(height: max(52, min(textHeight, 500)))
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("WidgetColor"))
                .shadow(radius: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(nsColor: .separatorColor))
                )
        )
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, cornerRadius: 16)
                .padding(-5)
        )
        .padding(.horizontal, 10)
        .animation(.snappy, value: textHeight)
    }

    private func handleTextChange() {
        // Check for newlines in the added text
        let startIndex: String.Index = if previousText.count < text.count {
            text.index(text.startIndex, offsetBy: previousText.count)
        } else {
            text.endIndex
        }

        let addedText = String(text[startIndex...])

        // logger.debug("Previous text: \(previousText)")
        // logger.debug("Previous text count: \(previousText.count)")
        // logger.debug("Text: \(text)")
        // logger.debug("Text count: \(text.count)")
        // logger.debug("Added text: \(addedText)")
        // logger.debug("Added text count: \(addedText.count)")
        if addedText.contains("\n") {
            // Attempt to detect Shift key
            // We have to make sure its not a paste with a newline too
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == false, NSApp.currentEvent?.modifierFlags.contains(.command) == false {
                // If Shift is not pressed, and a newline is added, submit
                text = text.trimmingCharacters(in: .newlines) // Optional: remove the newline
                action()
                // text = "" // Clear the text field after submission
            }
            // If Shift is pressed, just allow the newline (normal behavior)
        }
        previousText = text // Update previous text state for next change
    }
}
