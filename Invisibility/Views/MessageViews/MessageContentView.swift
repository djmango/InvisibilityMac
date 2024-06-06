//
//  MessageContentView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import MarkdownWebView
import SwiftUI

struct MessageContentView: View {
    @ObservedObject var message: APIMessage

    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool { MessageViewModel.shared.isGenerating && (message.text.isEmpty) }
    private var isLastMessage: Bool { message.id == MessageViewModel.shared.api_messages.last?.id }
    private var showLoading: Bool { isGenerating && isLastMessage }

    private var images: [APIFile] {
        MessageViewModel.shared.shownImagesFor(message: message)
    }

    var body: some View {
        // let _ = Self._printChanges()

        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? "Invisibility" : "You")
                .font(.custom("SF Pro Display", size: 13))
                .fontWeight(.bold)
                .tracking(-0.01)
                .lineSpacing(10)
                .opacity(0)
                .overlay(LinearGradient(
                    gradient: isAssistant ?
                        Gradient(colors: [.invisGrad1, .invisGrad2]) :
                        Gradient(colors: [.youText, .youText]),
                    startPoint: .leading, endPoint: .trailing
                ))
                .mask(
                    Text(isAssistant ? "Invisibility" : "You")
                        .font(.custom("SF Pro Display", size: 13))
                        .fontWeight(.bold)
                        .tracking(-0.01)
                        .lineSpacing(10)
                )

            ProgressView()
                .controlSize(.small)
                .visible(if: isGenerating && isLastMessage, removeCompletely: true)
            // HStack {
            //     Spacer()
            //     MessageLoaderView()
            //     Spacer()
            // }
            // .frame(maxWidth: .infinity)
            // .shadow(radius: 3)
            // .padding(.vertical, -20)
            // .visible(if: showLoading, removeCompletely: true)

            HStack {
                MessageImagesView(images: images)
                    .visible(if: !images.isEmpty, removeCompletely: true)

                // MessagePDFsView(items: message.pdfs_data)
                //     .visible(if: !message.pdfs_data.isEmpty, removeCompletely: true)
            }
            // .visible(if: !message.images_data.isEmpty || !message.pdfs_data.isEmpty, removeCompletely: true)
            .visible(if: !images.isEmpty, removeCompletely: true)

            MarkdownWebView(message.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
