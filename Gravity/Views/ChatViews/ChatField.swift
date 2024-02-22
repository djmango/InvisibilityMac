//
//  ChatField.swift
//
//
//  Created by Kevin Hermawan on 11/12/23.
//

import AppKit
import SwiftUI

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        context.coordinator.setupTextView(textView)
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context _: Context) {
        nsView.string = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView

        init(_ textView: CustomTextView) {
            self.parent = textView
        }

        func setupTextView(_ textView: NSTextView) {
            textView.isRichText = false
            textView.font = NSFont.preferredFont(forTextStyle: .title3)
            textView.backgroundColor = NSColor.clear // Making the background transparent
            textView.enclosingScrollView?.drawsBackground = false // Hiding the scroll view's background
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("Selector method is \(NSStringFromSelector(commandSelector))")
            if NSStringFromSelector(commandSelector) == "insertNewline:" {
                if NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false {
                    textView.insertNewlineIgnoringFieldEditor(self)
                    return true
                } else {
                    parent.onSubmit()
                    return true
                }
            }
            return false
        }
    }
}

/// A control that displays an editable text interface for chat purposes.
///
/// ``ChatField`` extends standard text field capabilities with multiline input and specific behaviors for different platforms.
public struct ChatField: View {
    @Binding private var text: String
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
        CustomTextView(text: $text, onSubmit: submit)
            .frame(height: 40)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("WidgetColor")) // Make sure to define "WidgetColor" in your asset catalog
                    .shadow(radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(nsColor: .separatorColor))
                    )
            )
            .padding(.horizontal, 10)
        // TextEditor(text: $text)
        // TextEditor(text: Binding(
        //     get: { text },
        //     set: { newValue, _ in
        //         if let _ = newValue.lastIndex(of: "\n") {
        //             submit()
        //         } else {
        //             text = newValue
        //         }
        //     }
        // ))
        // TextField("Message", text: $text, axis: .vertical)
        // .onSubmit { submit() }
        // .textFieldStyle(.plain)
        // .scrollContentBackground(.hidden)
        // .multilineTextAlignment(.leading)
        // .font(Font(NSFont.preferredFont(forTextStyle: .title3)))
        // .frame(height: 40)
        // .padding()
        // .background(
        //     RoundedRectangle(cornerRadius: 16)
        //         .fill(Color("WidgetColor"))
        //         .shadow(radius: 2)
        //         .overlay(
        //             RoundedRectangle(cornerRadius: 16)
        //                 .stroke(Color(nsColor: .separatorColor))
        //         )
        // )
        // .padding(.horizontal, 10)
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
