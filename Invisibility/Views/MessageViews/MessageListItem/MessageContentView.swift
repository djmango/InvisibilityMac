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
    private let message: Message

    init(message: Message) {
        self.message = message
    }

    private var isAssistant: Bool { message.role == .assistant }
    private var isGenerating: Bool { MessageViewModel.shared.isGenerating && (message.content?.isEmpty ?? true) }
    private var isLastMessage: Bool { message.id == MessageViewModel.shared.messages.last?.id }

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

            MessageImagesView(images: message.images_data)
                .visible(if: !message.images_data.isEmpty, removeCompletely: true)

            MarkdownWebView(message.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
