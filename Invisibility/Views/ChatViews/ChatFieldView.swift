//
//  ChatFieldView.swift
//
//
//  Created by Sulaiman Ghori on 22/02/24.
//

import AppKit
import OSLog
import SwiftUI

/// A view that displays an editable text interface for chat purposes.
struct ChatFieldView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatFieldView")

    @ObservedObject private var chatFieldViewModel: ChatFieldViewModel = ChatFieldViewModel.shared

    @FocusState private var promptFocused: Bool {
        didSet {
            // logger.debug("Prompt focused: \(promptFocused)")
        }
    }

    @State private var whoIsHovering: UUID?
    
    let columns = [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible())
   ]

    init() {
        promptFocused = true
    }

    var body: some View {
        // let _ = Self._printChanges()
        VStack {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(chatFieldViewModel.images) { imageItem in
                    ChatImageView(imageItem: imageItem)
                }
                ForEach(chatFieldViewModel.pdfs) { pdfItem in
                    ChatPDFView(pdfItem: pdfItem)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .visible(if: !chatFieldViewModel.items.isEmpty, removeCompletely: true)

            Divider()
                .background(Color(nsColor: .separatorColor))
                .padding(.horizontal, 10)
                .visible(if: !chatFieldViewModel.items.isEmpty, removeCompletely: true)

            ChatWebInputView()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .focused($promptFocused)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: 2)
        )
        .padding(.horizontal, 10)
        .onChange(of: chatFieldViewModel.images) {
            promptFocused = true
        }
        .onChange(of: chatFieldViewModel.shouldFocusTextField) {
            if chatFieldViewModel.shouldFocusTextField {
                promptFocused = true
                chatFieldViewModel.shouldFocusTextField = false
            }
        }
    }
}
