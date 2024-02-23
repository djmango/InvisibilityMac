//
//  ChatField.swift
//
//
//  Created by Kevin Hermawan on 11/12/23.
//

import AppKit
import OSLog
import SwiftUI

/// A control that displays an editable text interface for chat purposes.
///
/// ``ChatField`` extends standard text field capabilities with multiline input and specific behaviors for different platforms.
public struct ChatField: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "ChatField")

    @Binding private var text: String
    @State private var textHeight: CGFloat = 50
    @State private var previousText: String = ""

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
        ScrollView {
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .multilineTextAlignment(.leading)
                // .font(Font(NSFont.preferredFont(forTextStyle: .title3)))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("WidgetColor"))
                .shadow(radius: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(nsColor: .separatorColor))
                )
        )
        .padding(.horizontal, 10)
        .frame(height: max(52, min(textHeight, 500)))
        .animation(.snappy, value: textHeight)
    }

    private func handleTextChange() {
        // Check for newlines in the added text
        let startIndex: String.Index = if previousText.count < text.count {
            text.index(text.startIndex, offsetBy: previousText.count)
        } else {
            text.startIndex
        }

        let addedText = String(text[startIndex...])

        // logger.debug("Added text: \(addedText)")
        if addedText.contains("\n") {
            // Check if the difference contains a newline character and not caused by a Shift press
            // if text.count > previousText.count, text.last == "\n" {
            // Attempt to detect Shift key
            // We have to make sure its not a paste with a newline too
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == false, NSApp.currentEvent?.modifierFlags.contains(.command) == false {
                // If Shift is not pressed, and a newline is added, submit
                text = text.trimmingCharacters(in: .newlines) // Optional: remove the newline
                action()
                text = "" // Clear the text field after submission
            }
            // If Shift is pressed, just allow the newline (normal behavior)
        }
        previousText = text // Update previous text state for next change
    }
}
