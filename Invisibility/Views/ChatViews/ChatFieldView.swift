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

    var body: some View {
        VStack {
            HStack {
                ForEach(ChatViewModel.shared.images) { imageItem in
                    ChatImageView(imageItem: imageItem)
                }

                ForEach(ChatViewModel.shared.pdfs) { pdfItem in
                    ChatPDFView(pdfItem: pdfItem)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .visible(if: !ChatViewModel.shared.items.isEmpty, removeCompletely: true)

            Divider()
                .background(Color(nsColor: .separatorColor))
                .padding(.horizontal, 10)
                .visible(if: !ChatViewModel.shared.items.isEmpty, removeCompletely: true)

            ChatWebInputView()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
        }
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .padding(.horizontal, 10)
    }
}
