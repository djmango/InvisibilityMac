//
//  ChatFieldView.swift
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
struct ChatFieldView: View {
    @State private var whichImageIsHovering: UUID?

    private var action: () -> Void

    /// Creates a text field with a text label generated from a localized title string.
    ///
    /// - Parameters:
    ///   - action: The action to execute upon text submission.
    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        // Images
        VStack {
            HStack {
                ForEach(ChatViewModel.shared.images) { imageItem in
                    ChatImageView(imageItem: imageItem, whichImageIsHovering: $whichImageIsHovering)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .visible(if: !ChatViewModel.shared.images.isEmpty, removeCompletely: true)

            Divider()
                .background(Color(nsColor: .separatorColor))
                .padding(.horizontal, 10)
                .visible(if: !ChatViewModel.shared.images.isEmpty, removeCompletely: true)

            ChatEditorView(action: action)
        }
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
        .animation(.easeIn(duration: 0.2), value: ChatViewModel.shared.images)
    }
}
