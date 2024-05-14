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
    // private let message: Message
    private var message: Message

    private var message_content: Binding<String> {
        Binding {
            message.content ?? ""
        } set: { newValue in
            message.content = newValue
        }
    }

    init(message: Message) {
        self.message = message
    }

    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool { MessageViewModel.shared.isGenerating && (message.content?.isEmpty ?? true) }
    private var isLastMessage: Bool { message.id == MessageViewModel.shared.messages.last?.id }
    private var showLoading: Bool { isGenerating && isLastMessage }

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
                        Gradient(colors: [Color("InvisGrad1"), Color("InvisGrad2")]) :
                        Gradient(colors: [Color("YouText"), Color("YouText")]),
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
                MessageImagesView(images: message.nonHiddenImages)
                    .visible(if: !message.images_data.isEmpty, removeCompletely: true)

                // MessagePDFsView(items: message.pdfs_data)
                //     .visible(if: !message.pdfs_data.isEmpty, removeCompletely: true)
            }
            // .visible(if: !message.images_data.isEmpty || !message.pdfs_data.isEmpty, removeCompletely: true)
            .visible(if: !message.images_data.isEmpty, removeCompletely: true)

            MarkdownWebView(message_content)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
