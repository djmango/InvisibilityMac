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
    @StateObject private var viewModel: MessageContentViewModel

    private let isAssistant: Bool
    private let model_name: String

    init(message: APIMessage) {
        self.isAssistant = message.role == .assistant
        self.model_name = LLMModelRepository.shared.model_id_2_name(message.model_id)
        self._viewModel = StateObject(wrappedValue: MessageContentViewModel(message: message))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? model_name : "You")
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
                    Text(isAssistant ? model_name : "You")
                        .font(.custom("SF Pro Display", size: 13))
                        .fontWeight(.bold)
                        .tracking(-0.01)
                        .lineSpacing(10)
                )

            ProgressView()
                .controlSize(.small)
                .visible(if: viewModel.isGenerating && viewModel.isLastMessage, removeCompletely: true)

            HStack {
                MessageImagesView(images: viewModel.images)
                    .visible(if: !viewModel.images.isEmpty, removeCompletely: true)
            }
            .visible(if: !viewModel.images.isEmpty, removeCompletely: true)

            MarkdownWebView(viewModel.message.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
