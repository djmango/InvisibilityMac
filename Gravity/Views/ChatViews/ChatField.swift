//
//  ChatField.swift
//
//
//  Created by Kevin Hermawan on 11/12/23.
//

import SwiftUI

/// A control that displays an editable text interface for chat purposes.
///
/// ``ChatField`` extends standard text field capabilities with multiline input and specific behaviors for different platforms.
public struct ChatField: View {
    @Binding private var text: String
    private var action: () -> Void

    /// Creates a text field with a text label generated from a localized title string.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of the text field, describing its purpose.
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
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .multilineTextAlignment(.leading)
            .font(Font(NSFont.preferredFont(forTextStyle: .title3)))
            .onSubmit { submit() }
            .padding()
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
            .frame(height: 80)
            .keyboardShortcut(.return, modifiers: [])
    }

    private func submit() {
        if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
            text.appendNewLine()
            // Scroll to the bottom of the chat view
        } else {
            action()
        }
    }
}
