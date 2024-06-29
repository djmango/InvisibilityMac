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
    @AppStorage("width") private var windowWidth: Int = WindowManager.defaultWidth
    
    private let spacing: CGFloat = 5
    private let itemWidth: CGFloat = 150

    private var columns: [GridItem] {
        let availableWidth = CGFloat(windowWidth)
        let numColumns = max(1, Int((availableWidth / (itemWidth + spacing * 2)).rounded(.down)))
        return Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: numColumns)
    }

    @FocusState private var promptFocused: Bool
    @State private var whoIsHovering: UUID? = nil
    
    init() {
        promptFocused = true
    }

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(chatFieldViewModel.images, id: \.self) { imageItem in
                    ChatImageView(imageItem: imageItem, itemSpacing: spacing, itemWidth: itemWidth, whoIsHovering: $whoIsHovering)
                        .whenHovered{ hovering in
                            if hovering {
                                whoIsHovering = imageItem.id
                            }
                            if !hovering && whoIsHovering == imageItem.id {
                                whoIsHovering = nil
                            }
                        }
                }
                ForEach(chatFieldViewModel.pdfs) { pdfItem in
                    ChatPDFView(pdfItem: pdfItem, itemSpacing: spacing, itemWidth: itemWidth,  whoIsHovering: $whoIsHovering)
                        .whenHovered{ hovering in
                            if hovering {
                                whoIsHovering = pdfItem.id
                            }
                            if !hovering && whoIsHovering == pdfItem.id {
                                whoIsHovering = nil
                            }
                        }
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
