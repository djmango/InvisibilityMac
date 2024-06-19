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
    @State private var whoIsHovering: UUID?
    @ObservedObject private var chatViewModel: ChatViewModel = ChatViewModel.shared
    
    let columns = [
           GridItem(.flexible()),
           GridItem(.flexible()),
           GridItem(.flexible())
    ]

    public var body: some View {
        // let _ = Self._printChanges()

        // Items: Images, and PDFs
        VStack {
              LazyVGrid(columns: columns, spacing: 20) {
                  ForEach(chatViewModel.images) { imageItem in
                      ChatImageView(imageItem: imageItem, whoIsHovering: $whoIsHovering)
                  }
                  ForEach(chatViewModel.pdfs) { pdfItem in
                      ChatPDFView(pdfItem: pdfItem, whoIsHovering: $whoIsHovering)
                  }
              }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .frame(width: WindowManager.shared.is_resized ? WindowManager.resizeWidth : WindowManager.defaultWidth)
            .visible(if: !ChatViewModel.shared.items.isEmpty, removeCompletely: true)

            Divider()
                .background(Color(nsColor: .separatorColor))
                .padding(.top, 10)
                .padding(.horizontal, 10)
                .visible(if: !ChatViewModel.shared.items.isEmpty, removeCompletely: true)

            ChatEditorView()
        }
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
        .animation(.easeIn(duration: 0.2), value: ChatViewModel.shared.items)
    }
    
    private func totalCount () -> Int {
        return ChatViewModel.shared.images.count + ChatViewModel.shared.pdfs.count
    }
}
